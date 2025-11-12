---
title: "Intercontinental Kubernetes Cluster: Lessons Learned"
date: 2025-11-12T13:00:00+02:00
---
Two years ago, I started building a Kubernetes cluster. Because I wanted it to be highly available, I decided to make sure the nodes were on different internet connections. Because I like owning my data, I wanted these locations to be my home or the homes of trusted family members.

This means I ended up with nodes:

- At my home in Germany
- At my mother's home in the US
- At my fiancée's mother's home in the US

all connected to residential internet connections from different providers.

And then, because I wasn't content to deal with availability zones and data replication, I made this all one cluster. For those of you who aren't already looking at me like I'm nuts: This is nuts.

In standard production deployments, one usually has services replicated both within availability zones and between availability zones. In theory, this means that you can arbitrarily restart running pods within a zone (eg: to upgrade something to a new version) and are resilient to problems (eg: AWS-US-East-1 goes down, again). But that comes with engineering problems and inefficiencies. First, you have to device where data will reside, how to replicate it and how to keep things in sync. Then you have to engineer services to deal with all of this.

I did not want to do all this work. I want storage to be storage, and I want to be able to run software that doesn't understand clustering. So I decided to accept the performance hit and interconnect these nodes directly in order to reduce the complexity. While I normally work in high performance computing, this will be decidedly low performance computing.

As usual, I started off documenting this project in every detail. However, it turns out this is complicated enough I want it in its final configuration before I try to write that up.

In the meantime, however, I do want to present some lessons learned, in the hope that they're useful for anyone trying something similarly crazy.

# Basics

As I mentioned before, I have three nodes. Each is an HPE Microserver with at least 10TB of usable storage space. Most locations have an out-of-band access node (a raspberry pi with a data-only cell modem) so that if the node goes down, I can get to the BMC and check on it/restart it.

The nodes are interconnected with a VPN. I chose [Tailscale](https://tailscale.com/), with a cloud-hosted [Headscale](https://headscale.net/stable/) server. This saves me the effort of manually setting up a mesh so that all the nodes can talk to each other. Additionally, Tailscale's handling of NATs allows the nodes to directly connect to each other without me having to open ports on various routers.

I'm running [k3s](https://k3s.io/), with a single controller node. This controller node is also cloud-hosted, although I have plans to change to having a distributed controller cluster. This will likely require adjusting etcd configuration within k3s as well as solving other latency-related issues.

Clustered storage is provided by [Ceph](https://ceph.io/en/) (with [rook](https://rook.io/) managing everything).

Networking I have left relatively unchanged, but am eyeing a change to [Istio](https://istio.io).

Typically, cloud and HPC systems are thought about as having compute, storage, and networking. Therefore, I have broken the discussion down into these same categories.

# Compute

Running over the internet means that the greatest barrier to performance is the speed of transmission between nodes, which is bounded by the speed of light. Therefore, as long as you have enough memory to run the applications and enough processor speed that the node isn't getting overwhelmed, compute is not going to be your bottleneck.

**Lesson 1**: Compute is irrelevant.

Initially, one of my nodes was a Raspberry Pi with 4GB of memory. Occasionally, it would run out of memory and the OOMKiller would fire and kill something - usually something critical, like the VPN, thus taking the node offline. So do make sure you have enough resources on your nodes to actually run the applications.

**Corollary to lesson 1**: ... As long as you have enough resources for the applications to run

# Storage

Storage is probably the single point that has caused me the most heartache setting this up. Initially, I was hoping that simply using a clustered kubernetes storage engine would suffice, even if the performance would be terrible. That, unfortunately, was not true.

## Longhorn

Initially, I chose [Longhorn](https://longhorn.io/) as the storage engine, since it promised like-local performance with clustered replication of data.

**Lesson 2**: Longhorn performs poorly over the internet

**Caveat**: I was running Longhorn with only two replicas of data. I'm not sure if it would have done better with 3, but based on what I saw, I am skeptical.

In practice, even short network drops lead to Longhorn replicas getting out of sync. This then lead to Longhorn starting a resync - which must be of the complete volume, not merely of whatever part changed during the network disruption. With high-speed networks within a data center, this is annoying, but not too bad. Over the internet when you can sync ~20 GB/hour... It wouldn't even get back in sync before the next failure. Longhorn also had a lot of trouble completing syncs, even without disruptions - it's unclear if this was due to timeouts, high packet drop rates, or another cause. It really seemed as if Longhorn was expecting the network to operate perfectly.

And then there were the volume corruption issues. Several times, I had Longhorn go "[split brain](https://en.wikipedia.org/wiki/Split-brain_(computing))" - that is, into a state where more than one node thought it had the primary copy of the volume and was writing to it. This later meant having to pick a copy and designate it as the primary, losing whatever changes had been made to the copy I didn't pick. Split brain is a fundamental problem in distributed systems when one's model includes an unreliable network (and not using an odd number of nodes to form a quorum). It seems Longhorn's model assumes the network is perfectly reliable and that it is only concerned with node/disk failures. That likely works well enough in a datacenter, but is not a viable model when working over the internet.

## Ceph

After it was obvious that Longhorn wasn't a viable solution, I began moving data to Ceph. Ceph's [requirements](https://docs.ceph.com/en/latest/start/hardware-recommendations/#networks) list a 10Gb/s network. My internet connections can provide 20 Mb/s. This is going to fail abysmally, isn't it?

Surprisingly no.

**Lesson 3**: Despite the requirements, it is possible to run Ceph between nodes at internet speeds.

Obviously, this comes with performance hits. Write speeds are often about 1-2 MB/s. (Reads are somewhat better, especially if things are on the local node). After removing a 500 GB OSD it takes 4-6 days to finish rebalancing the PGs.

**Corollary to lesson 3**: ... but performance is pretty bad.

One other observation: Using RBDs is probably a bad idea. When network disruptions happen, the linux RBD driver will lose connection and mark the device read-only. Sometimes it is unable to regain connection and then the device gets stuck read-only until the pod using it is shut down, the PVC unmounted, and the pod restarted. Sometimes even this wasn't enough and a few times I had to reboot nodes in order to allow devices to be writable again.

CephFS-based PVCs are much more robust to this. I've not yet seen one go into read-only mode. So although certain operations might stall for a long time, the PVC always eventually recovers and the pod is able to continue.

**Lesson 4**: CephFS-based PVCs are much more robust than RBD-backed PVCs in this scenario. Use CephFS PVCs unless forced to provide a block device.

## Local storage

A lot of software, once stuck in a pod, requires that there be a single PVC holding the data that can be accessed from any node. For that software, you just can't avoid using Ceph-backed storage.

However, there are entire classes of software that already come with their own clustering mechanisms. For example, databases. For these services, you can create PVCs that use local storage on the nodes. The software then has access to fast local storage and if a node goes down, the software already has built-in mechanisms to recover and still provide services. This is also true for software that is designed to scale horizontally - better to have multiple copies with fast storage and lose an instance than to rely on slow network storage.

**Lesson 5**: Just because you have clustered storage doesn't mean you have to use it. Prefer running multiple copies of software that can cluster, each with local storage over a single copy with network storage.

When I changed my databases to local storage, I saw query times reduce from unusably long (seconds to minutes) down to milliseconds.

As a side comment, I ended up using [OpenEBS lvm-localpv](https://github.com/openebs/lvm-localpv) as my local storage driver. All my systems have lvm set up for their storage so that I can easily grow partitions, and this lets me put the Kubernetes PVs directly alongside other data. I even use them for the PVs backing the Ceph OSDs so that I can grow the OSDs later (possibly keeping Ceph's memory usage down by not running a second OSD).

## S3-interfaces

In this configuration, I also observed that software which supports both filesystem-based and S3-based storage will often perform better on the S3-based storage. My theory is that because the S3 storage is already expected to be (relatively) slow and can process various requests in parallel, the software is already engineered to take advantage of those features and assumes a slow network.

**Lesson 6**: If given a choice between filesystem-based storage and S3-interfaced storage, pick the S3-interfaced storage.

(As a side-note, don't forget that Ceph can provide S3-based storage.)

# Network

Because transmission time is the bound on the performance of a network cluster, there are some really big gains to be made by tweaking it. If a piece of software uses multiple pods, it's possible for the pods to get spread across nodes. When the nodes are all in the same datacenter, no big deal - it's a tick slower, but not noticeable on a human scale. However, in this scenario, it can add a lot of time.

Imagine you're me, in Germany, making a request to a web service that writes to a database. The service is running on a US node, and the database primary is running on the German node.

1. I make a request which goes to the US node: 200ms network transit time
2. The web service requests something from the database: 200ms network transit time
3. The web service writes to the database: 200ms network transit time
4. The web service sends the response to me: 200ms network transit time

So a simple web request took 800ms - almost an entire second! Imagine if the service needed to do multiple rounds of reading and writing - this request could quite quickly take seconds.

Now, let's pretend the database and the web service are on the same node:

1. I make a request which goes to the US node: 200ms network transit time
2. The web service requests something from the database: 3ms local routing time
3. The web service writes to the database: 3ms local routing time
4. The web service sends the response to me: 200ms

Now the total is just 406ms - almost half the time. And if the request were more complicated or required more interaction with the database, the speedup here could be huge!

**Lesson 7**: Having pods that interact with each other be local to each other gives huge performance benefits, observable at the human scale.

To make the pods be local to each other, there are two settings you should consider for every service: pod affinity and traffic policy. These cover different scenarios, but to the same end effect.

When there are two pods that are singletons (eg: a web service with storage and a database primary), those two pods should to be placed on the same node. Pod affinity is the correct way to do that. As a concrete example, here's how I force my web services to run on the same node as their [Cloud-native Postges](https://cloudnative-pg.io/) primary (at least at scheduling time):

```yaml
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: kubernetes.io/hostname
            labelSelector:
              matchLabels:
                cnpg.io/instanceRole: primary
```

This won't guarantee that this pod moves if the primary role moves - this only applies at pod start. However, my expectation is that the primary role only shifts if a node goes offline. In that case, both pods will be rescheduled, so this should still work. And in the worst case, things are slow, but no slower than they are without this tweak.

If, however, either of the pods can be clustered (eg: horizontally scalable services, such as S3 frontends or [Thanos' `storagegateway`](https://thanos.io/tip/components/store.md/)), you're better off tweaking the Kubernetes `service` via [`internalTrafficPolicy`](https://kubernetes.io/docs/concepts/services-networking/service-traffic-policy/) and [`externalTrafficPolicy`](externalTrafficPolicy). These force kubernetes to keep traffic local when looking for instances of a service. If there is no pod on the local node that the service can send traffic to the traffic will be dropped. Therefore, they only work *if an instance of that service runs on every node* (or if your pod is forced to run on a node that has an instance of the service). If not, some nodes will have no access to that service. Hence, this only applies to horizontally scalable services, because those can be scaled to run on every node. This may also work for services that have their own clustering mechanisms and allow writing to any instance, even if they internally designate a primary that handles all write traffic.

# Wrap-up

Running a kubernetes cluster over the internet is never going to be performant. But by correctly selecting storage, carefully selecting software, and keeping a good eye on network data flows, it's possible. While this scenario is a bit bizarre, it does work and I hope these lessons learned are useful for anyone who wants to run kubernetes in a similarly network-constrained manner.
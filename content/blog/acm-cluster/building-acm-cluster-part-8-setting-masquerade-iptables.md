---
title: "Building the ACM Cluster, Part 9: Setting up masquerade with iptables"
date: 2012-12-15 18:22:19
slug: "building-acm-cluster-part-8-setting-masquerade-iptables"
categories:
  - "ACM"
  - "ACM Cluster"
---

Alright! Lets get this started again.  There is one last thing we need to do in order to have networking on the cluster functional.  Right now, the nodes inside the cluster can't speak to the outside world.  While we set up the head node to be able to speak to things on every interface, we haven't yet told it how to move traffic from one interface to another.

# Making the Gateway

In normal clusters, there are three types of notes - workers, gateways and head nodes.  Workers do whatever task the cluster is intended for.  Head noes manage the workers.  And finally, gateways, which allow the worker nodes to communicate with things outside the cluster.

Gateways are needed because clusters often use IP addresses which are not publicly routeable.  The gateway allows the entire cluster to sit behind one IP address and is in charge of routing traffic properly.  This process is called [Network Address Translation](http://en.wikipedia.org/wiki/Network_address_translation).  In many ways, this makes the gateway like your home router.

Anyway, we're going to be using iptables to implement NAT.  Fortunately, this is a cmmon use for iptables, so it is very simple to set up.  Simply type the following:

```shell
# iptables --table nat --append POSTROUTING --out-interface bond0.2 -j MASQUERADE
# iptables --table nat --append POSTROUTING --out-interface bond0.3 -j MASQUERADE
# iptables --append FORWARD --in-interface bond0.def -j ACCEPT
```

and check that it took.

```shell
# iptables -L -t nat<
```

You should see something like the following:

```shell
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination         

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination         
MASQUERADE  all  --  anywhere             anywhere            
MASQUERADE  all  --  anywhere             anywhere            
MASQUERADE  all  --  anywhere             anywhere            

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination         
```

Finally, we need to save these setting so they get recalled on the next boot.  On a CentOS machine this is trivially simple:

```shell
# service iptables save
```

And done.  That was nice and simple.
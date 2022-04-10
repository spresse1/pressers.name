---
title: "Building the ACM VM Cluster, Part 2: Network design"
date: 2012-09-08 21:04:35
slug: "building-acm-vm-cluster-part-2-network-design"
categories:
  - "ACM"
  - "ACM Cluster"
---

Welcome to part 2 of my series of posts on building the ACM VM cluster!  [Part 1](/2012/09/08/building-acm-vm-cluster-part-1/) covered the hardware and software that will be used in the cluster.  Part 2 is going to focus on network design.

# Introduction

Typically in clusters there are two networks (usually represented by IP ranges, though sometimes actually physically separate): management and work.  Management is typically mostly for master node to worker node communication (giving and getting work orders), whereas work is for intercommunication between nodes.  However, in our case, we are going to need three separate networks: management, work and fiber.  Why?  Well, we have fiber cards in the nodes, which go faster then the ethernet cards that are in the nodes, and I'd like to take advantage of that.

# Physical Networks

As is probably obvious, we'll be using two distinctly different physical networks - the fiber network and the ethernet network.  Both the management and the work network will run over ethernet, while the fiber is going to be dedicated to the cluster file system.  Most simply, this is because the filesystem will produce the most traffic and gets the most advantage from having a speedy network.

# IP-Layer Networks

So now we need to think about what IP address space to use in this cluster and how to divide it up.  When I know I'm in a situation like this one, where my private network is going to be more-or-less isolated from the rest of the world, I like to go with the largest address space possible to reduce the changes I need to migrate later.  In this case, I can't use the 10.0.0.0/8 network, since JHU uses this internally on their networks.  This would unfortunately cause routing conflicts, which I'd rather not do.  One possible solution would be a double-NAT, but this seems like too much complexity when a smaller space will do just fine.  Therefore, I'm choosing to use 172.16.0.0/12 as the private IP address space within this cluster.  Since many of the VMs will run globally-addressable services, they'll have globally addressable IP addresses.  However, the cluster (other than the gateway nodes) won't care about this.  I also prefer to err on the side of over-assigning the IP ranges here, so these are fairly large ranges:

*   Management: 172.16.0.0/15 (172.16.0.0-172.17.255.255)
*   Node Network: 172.18.0.0/15 (172.18.0.0-172.19.255.255)
*   Fiber Network: 172.20.0.0/15 (172.20.0.0-172.21.255.255)

XCat will also want a range for DHCP addresses.  So I've picked the next range as the DHCP network:

*   DHCP: 172.22.0.0/15 (172.22.0.0-172.23.255.255)

And finally, the rest of this space can be given to any VMs that do not need globally addressable IP addresses.

# Conclusion

Though fairly complex, this IP address space setup takes into account all of the various typical divisions in a cluster network, as well as all of the physical and software requirements.  I therefore think this is going to be a sufficient division.
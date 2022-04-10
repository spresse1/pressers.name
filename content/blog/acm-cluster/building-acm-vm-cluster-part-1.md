---
title: "Building the ACM VM Cluster, Part 1: Hardware"
date: 2012-09-08 19:48:49
slug: "building-acm-vm-cluster-part-1"
categories:
  - "ACM"
  - "ACM Cluster"
---

So I have a vision for the ACM systems - I'd like to make it so we are as redundant as possible and we can do updates to systems without having to take them offline.  The obvious answer to this is using VMs, in a cluster.  Fortunately, the ACM recently received a donation of the old [DLMS](http://center.ncet2.org/index.php?option=com_patents&controller=awards&tmpl=component&view=awards&layout=award&frame=awards&user=10274&id=86559_nsf) cluster from physics (as well as three more recent Dell servers from JHU Housing and Dining).  This is the perfect opportunity for me!  So off we go, down the rabbit hole (again).

This post is going to focus on cluster design - first, a description of the hardware (since we didn't get to choose it, I wont be covering why this hardware), then a description of the software architecture and the whys of each software choice.

#  Hardware

## Head Node (Dell PowerEdge 2950)

4x Intel Xeon 5160 @ 3Ghz

4GB RAM

3x300GB SAS drives in hardware RAID5, approximately 600GB usable.

## Cluster Nodes

2x AMD Opteron 244 @1.8GHz (Note: these have no hardware virtualization built in!)

RAM Varies, at least 2GB

40 GB IDE HDD

Myricom 2ME Fiber card (Note: this will restrict operating system choice - I am only able to get drivers for these on CentOS.  Maybe Debian, if I'm lucky).

# Software

## Cluster Management - XCat 2

On the recommendation of the former DLMS systems administrator, I am using [XCat](http://xcat.sourceforge.net/) to manage the cluster.  XCat provides a very powerful way to manage nodes.  When fully set up, it is possible to simply plug a new node in, power it on, and have to kickstart to the proper operating system.  In some configurations, XCat is even capable of remotely powercycling nodes.  I don't yet know if we'll be able to do this in our configuration, but I hope so.

XCat also has some very powerful image creation tools, which I plan to take full advantage of.

XCat uses yum-based package management, which then ties us into a yum-based operating system.  But, since the fiber cards (as mentioned above) require us to use CentOS, this isn't a problem.

## Gateway Node Redundancy - Keepalived

One of the critical goals of this cluster is to get as close as possible to 100% uptime.  Obviously this isn't possible if every time the gateway node (which serves much like your home router - it aggregates outbound traffic) is rebooted the entire cluster loses connectivity.  So what I need is two gateway nodes, set up so that if one goes offline, the other can immediately pick up all incoming and outgoing traffic.  The simplest solution to this is to use the [Virtual Router Redundancy Protocol](http://en.wikipedia.org/wiki/Virtual_Router_Redundancy_Protocol) to to failover.  Keepalived is a well-established package for doing this and makes it quite simple.  It is also extensible to doing failover and load balancing in services, which may come in handy later.

## Virtualization - Xen

This is mostly for tradition - the ACM already uses Xen on Luna (which I've [written about before](/2012/09/08/luna-case-study-failure/)) and I'd like to keep using it.  Primarily because I have no complaints, but also for ease of transition.

## Clustered File System - ???

I'm going to be dedicating as much space as I can to a clustered, redundant filesystem for VM storage.  But I honestly dont know what I'll use (because I haven't done the research yet).  Some possibilities:

*   GFS
*   GlusterFS
*   AFS?

## VM Management - Ganeti

[Ganeti](http://code.google.com/p/ganeti/) is a piece of VM management software that ties in well to Xen and should make it quite simple to toss VMs (even while running!) between nodes.  This will be extraordinarily useful when upgrading the operating systems on the nodes.

# Conclusion

So there you have it!  The physical and the software to be used in the ACM VM cluster.  Coming up in part 2: network design.
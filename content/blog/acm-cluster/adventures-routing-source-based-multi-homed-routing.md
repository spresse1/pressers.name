---
title: "Building the ACM Cluster, Part 8: Adventures in Routing: Source Based (Multi-homed) Routing"
date: 2012-10-17 12:29:56
slug: "adventures-routing-source-based-multi-homed-routing"
categories:
  - "ACM"
  - "ACM Cluster"
---

(This post is related to the ACM cluster build.  However, it is really generic systems stuff and not terribly related to the actual cluster build.  It is much more closely related to quirks of JHU networking.)

# The Problem

JHU has two distinct networks - firewalled and firewall-free.  (In truth there are more and there are gradations, but these are the two JHUACM has IP allocations on.)  Some services cannot be run form inside the firewalled network.  For these the ACM has a small firewall-free allocation.  Because the cluster will be hosting VMs inside both networks, it needs to be capable of routing traffic from both.  This means doing something called source-based routing or multihomed routing.  This refers to the fact that this machine will have two connections to the internet.  Typically, this is a very rare setup - Multihoming is usually used at the ISP or datacenter level, rather than at the level of the individual box.

# The Solution

The solution is to convert linux to source-based routing by manipulation of iproute2\.  We can add additional rules and rule tables to intercept traffic and send it out the right interface before falling back to the default route system linux usually uses.  On order to do this, we're going to have to manipulate these files: `/etc/iproute2/rt_tables`, `/etc/sysconfig/network-scripts/route-[ifname]`, `/etc/sysconfig/network-scripts/rule-[ifname]` where `[ifname]` is the interface name.

This process takes several steps.  First we need to add new rule tables, then set up per-route interfaces.

## Adding Rule Tables

First, lets take a look at `/etc/iproute2/rt_tables`, which defines the rule tables that iproute2 evaluates.  By default on my CentOS 6.3 machine, it looks like this:

```shell
#
# reserved values
#
255	local
254	main
253	default
0	unspec
#
# local
#
#1	inr.ruhep
```

This file is in the format of

```
number	name
```

Table numbers are used to assign priority to different tables of routing rules.  Tables with lower numbers are checked first, followed by the higher numbered ones.  Table numbers go up to 255, so the last few are already taken.  We can add tables anywhere in this file and they'll be evaluated in numerical order.  So lets add a couple lines.  In my case I've added tables for bond0.2 and bond0.3\.  You'll want to add one rule for each interface.

```shell
1	source.bond0.2
2	source.bond0.3
```

Your tables can be named whatever you'd like.  I prefer explicit naming, so I've named them to be fairly clear about that.

## Setting Up Per-Interface Routes

There are two steps to this section.  First, we'll set rules for when iproute2 should look at each table.  Then, we'll actually create the routing rules that go in these tables.

Lets get started with the first step.  In CentOS, we'll edit `/etc/sysconfig/network-scripts/rule-[ifname]`  in order to say which rules should be applied to the tables (based on which interfaces are up).  Yes this is a little backwards - we apply the rules in tables based on which interfaces are up.  However, this way, we can use the same table over multiple interfaces, reducing the redundancy in configuration.

Anyway, lets put some rules in `/etc/sysconfig/network-scripts/rule-bond0.3`:

```shell
from 128.220.70.63 tab source.bond0.3
```

This is actually the entire contents of my `rule-bond0.3` file.  I've told iproute2 to apply the table (tab) `source.bond0.3` to any traffic coming from `128.220.70.63`.

Okay, now lets move on and actually put some rules in source.bond0.3\.  Edit `/etc/sysconfig/network-scripts/rule-bond0.3` and insert (the file was previously empty):

```shell
128.220.70.0/24 dev bond0.3 src 128.220.70.63 table source.bond0.3
default via 128.220.70.1 dev bond0.3 table source.bond0.3
```

These are the same rules (and same syntax) you'd use with `ip route add`, just drop the `ip route add`.  The two rules here are just the basic linux routing rules - send things on my local network directly to the local network and send everything else through a gateway - with the twist that the two of them are in the source.bond0.3 table.  Since this table only gets read for traffic coming from this network, this is effectively a routing table that affects just traffic from this network.  This way, we can have a default route and gateway for each interface, which allows traffic to always leave from the right interface.

And now these last two steps need to be repeated for each interface you'd like involved in source-based routing.

# Conclusion

While I don't necessarily understand the design decision on the part of linux to not do source-based routing by default, I do appreciate how simple it is to set up with CentOS.  Now that this is set up, I can get started on configuring a NAT for internal traffic - the next (and hopefully final) step in having networking set up for the ACM cluster.
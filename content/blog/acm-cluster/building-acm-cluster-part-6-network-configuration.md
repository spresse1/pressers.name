---
title: "Building the ACM Cluster, Part 6: Network Configuration"
slug: "building-acm-cluster-part-6-network-configuration"
date: 2012-09-09 21:51:04
categories:
  - "ACM"
  - "ACM Cluster"
---

In [part 5](/2012/09/09/building-acm-vm-cluster-part-5-xcat-configuration/) of this series, I covered the generic xCat setup and we told it how the network was set up.  We've done little bits of network setup before (like setting our switches up for SNMP read access in the public community).  Now we're going to do quite a bit more.

# Telling xCat where Nodes Are

xCat has this wonderful ability to know what a newly plugged in machine is, based on where it is on a switch.  In my case, I have the first management node on eth-switch1's 1st port, second management on the second port.  I then have the fiber switch's management interface on the 3rd port, and nodes are ports 4-20\.  The following set of commands encapsulates this, though you'll note that I've intentionally not made any entries for the management nodes - no point in confusing xCat by doing so.

```shell
# nodech myricom-switch switch.switch=eth-switch1 switch.port=3
# nodech compute switch.switch=eth-switch1 switch.port='|\D+(\d+)$|($1+3)|'
```

Notice that I've again used a regexp to assign ports.

# Peek at How xCat Sees Networks

One of the many "cool" features of xCat is network auto-detection on start.  So lets see how xCat sees the network around it:

```shell
$ tabdump networks
```

Heres what my unconfigured output looks like:

```shell
#netname,net,mask,mgtifname,gateway,dhcpserver,tftpserver,nameservers,ntpservers,logservers,dynamicrange,nodehostname,ddnsdomain,vlanid,domain,comments,disable
"10_1_10_0-255_255_255_0","10.1.10.0","255.255.255.0","eth0","10.1.10.1",,"10.1.10.114",,,,,,,,,,
"172_16_0_0-255_240_0_0","172.16.0.0","255.240.0.0","eth1","<xcatmaster>",,"172.16.0.2",,,,,,,,,,
```

(Note: 10.1.10.0/24 is my upstream router while building this cluster).

Those network names are rather ugly, aren't they?  Lets fix those:

```shell
# chtab netname=10_1_10_0-255_255_255_0 networks.netname="external"
# chtab netname=<span>172_16_0_0-255_240_0_0</span> networks.netname="internal"
```

Now, lets configure the internal network:

```shell
# chtab netname=internal networks.gateway=172.16.0.1 networks.dhcpserver=172.16.0.1 networks.tftpserver=172.16.0.1 networks.ntpservers="172.16.0.1" networks.logservers="172.16.0.1"
```

# Set up DHCP Ranges

Throughout all of this I've been referring to xCat's ability to autodetect nodes.  One of the things it need to do this is a range of IP addresses it can give out to nodes that it doesn't know yet.  In my case, I've designated 172.22.0.0/15 as the DHCP range.  So lets tell xCat this:

```shell
# chtab netname=internal networks.dynamicrange=172.22.0.1-172.23.255.254
```

# Network Cleanup

xCat uses a magic discovery kernel to find new nodes on the network.  Whenever we make changes to the network configuration, we have to regenerate it:

```shell
# mknb x86_64
```

Now, lets rebuild our network configuration:

```shell
# makedns
```

And lets restart DNS, then make sure that DNS will start properly on reboot:

```shell
# service named restart
# chkconfig --level 345 named on
```

# Tell Nodes where to find Important Details

We need to tell xCat what the installation setup of the nodes is.  To do this, run:

```shell
# nodegrpch compute noderes.primarynic=eth0 noderes.tftpserver=[management node name] noderes.installnic=eth0 noderes.nfsserver=[management node name] noderes.netboot=pxe
```

In this command, we've told the compute nodes which network interface they should use by default and where to find our management node for both tftp and nfs, which will be needed in the install process.

# DHCP

Now lets make a DHCP configuration:

```shell
# makedhcp --new
```

And start DHCP, then make sure it autostarts on boot:

```shell
# service dhcpd start
# chkconfig --level 345 dhcpd on
```

# Add Non-autodiscoverable MAC Addresses

Some nodes (in my case, all of the switches) are not auto-discoverable.  If this is the case, you'll need to manually tell xCat what the mac address is.  That can be done with a command like this:

```shell
# nodech [node] mac.mac=[macaddr, with colons]
```

# Conclusion

In the part we did rather a lot, didn't we?  We configured the network and started two new services - named and dhcpd - which will be critical to autodiscovering nodes.  Next up, we'll be building an operating system image for the nodes.
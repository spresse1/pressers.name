---
title: "Building the ACM VM Cluster, Part 3: Mangement Node Setup - Keepalived"
date: 2012-09-08 21:45:31
slug: "building-acm-vm-cluster-part-3-keepalived"
categories:
  - "ACM"
  - "ACM Cluster"
---

In [part 2](/2012/09/08/building-acm-vm-cluster-part-2-network-design/) of this series, I covered the network design - the last theoretical piece of design we need.  Now let's do some practical stuff!  In this section I'm going to cover base network setup and keepalived installation on the management node.

# Prerequisites

For this I've assumed you already have a set up CentOS machine.  In my case, its CentOS 6.3 (64-bit) though this may of course vary, in which case, refer to the [XCat documentation](http://sourceforge.net/apps/mediawiki/xcat/index.php?title=XCAT_Documentation) to see any differences.

# Procedure

Before we dive into this, lets establish some conventions.  Commands, code, or something you'll see in a system file looks

```shell
Like this.
```

Commands will be prefixed with either $ (for commands you can run as a normal user) or # (for commands to be run as root or with sudo).  I use sane-editor to represent the text-editor of your choice (no flame wars here!)

## Onwards! Disable SELinux

First, lets disable SELinux (it might step on our toes.  Please feel free to reenable it later if you'd like it)

```shell
# sane-editor /etc/sysconfig/selinux
```

Change the line that reads:

```shell
SELINUX=enforcing
```

to

```shell
SELINUX=disabled
```

Save, exit, and reboot.

## Enable Network Interfaces on Boot

CentOS by default doesn't start any network interfaces on boot.  Obviously since networking is such a big part of this, we want network on boot.  In my head node, I've chosen to use eth0 as my external network and eth1 as the interface internal to the network.  CentOS keeps network configuration in `/etc/sysconfig/network-scripts/ifconfig-[ifname]`, where ifname is the name of the interface (so eth0 and eth1 in this case).

So, lets edit `/etc/sysconfig/network-scripts/ifconfig-eth0 `and set it to start on boot and get its address via DHCP.

```shell
# sane-editor /etc/sysconfig/network-scripts/ifconfig-eth0
```

And change:

```shell
ONBOOT="no"
```

to

```shell
ONBOOT="yes"
```

Now, on to eth1\.  In my management network, I've chosen to assign 172.16.0.1 as the floating gateway address, so that won't get statically assigned to an interface.  Since this is the management node, lets give it the next address in sequence - 172.16.0.2\.  The following is my `/etc/sysconfig/network-scripts/ifconfig-eth1`:

```shell
DEVICE="eth1"
BOOTPROTO="none"
HWADDR="[mac address]"
NM_CONTROLLED="yes"
ONBOOT="yes"
TYPE="Ethernet"
UUID="[your uuid]"
NETWORK=172.16.0.0
NETMASK=255.240.0.0
IPADDR=172.16.0.2
USERCTL=no
```

A few notes on this configuration:  I've used the netmask for 172.16.0.0/12 because xCat will use this to try to autoset its network configuration.  I'm going to use the /12 netmask for all statically configured IPs for just this reason.

For more on this sort of configuration, see the [CentOS page on these configurations](http://www.centos.org/docs/5/html/5.2/Deployment_Guide/s2-networkscripts-interfaces-eth0.html).

Now, lets bring up the interfaces and check that everything worked okay:

```shell
# ifup eth0 && ifup eth1
# ifconfig
```

If everything went well, your eth0 should have a DHCP address, and your eth1 the address assigned to it.  Stop here and fix it if they don't.

## Install Keepalived

Unfortunately keepalivd isn't a core package.  In order to install keepalived, we'll need to set our management node up to use [EPEL, the Extra Packages for Enterprise Linux](http://fedoraproject.org/wiki/EPEL).  EPEL is part of fedora, a similar distribution to CentOS.  To get EPEL enabled, run the following:

```shell
# rpm -Uvh 'http://ftp.linux.ncsu.edu/pub/epel/6/i386/epel-release-6-7.noarch.rpm'
# yum update
```

Okay, now you're ready to install keepalived:

```shell
# yum install keepalived
```

## Configure Keepalived

Now, lets configure keepalived.  I've included my entire configuration below.  Note that if you want the two gateway nodes to have a shared external IP address, you'll have to set that up as well, though I haven't done that in this configuration.

```shell
! Configuration File for keepalived

global_defs {
   notification_email {
     [your email]
   }
   notification_email_from [some address]
   smtp_server [server]
   smtp_connect_timeout 30
   router_id [SOME_ID]
}

vrrp_instance VI_1 {
    state MASTER
    interface eth1
    # This stanza added to make sure that we fall/fail over if any interface
    # goes down.  Since we're forwarding things, this would seem to make sense.
    track_interface {
        eth0
        eth1
    }
    virtual_router_id 151
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass [a password - typically 4 digits]
    }
    virtual_ipaddress {
        172.16.0.1/12 brd 172.31.255.255 dev eth1
    }
}```

And now, lets make keepalived start on reboot:

```shell
# chkconfig --level 345 keepalived on
```

and start keepalived:

```shell
# /etc/init.d/keepalived start
```

And that's it!  Keepalived is now configured and running.  If this gateway node goes offline, another one which is running the same keepalived configuration will pick up the IP address and be the router.

## Configuring IP Routing

This section is all about making the gateway node act properly as a gateway - that is, route traffic from an internal interface to an external one.  First, lets get rid of any IPtables rules that are laying about.  Don't worry, you can still add your own back in later.

```shell
# iptables --flush
# service iptables save
```

Now, lets enable IPv4 forwarding.

```shell
# sane-editor /etc/sysctl.conf
```

Find the lines that read 

```shell
# Controls IP packet forwarding
net.ipv4.ip_forward = 0
```

and change them to:

```shell
# Controls IP packet forwarding
net.ipv4.ip_forward = 1
```

Now, lets reload the system configuration:

```shell
# sysctl -p
```

## IPTables NAT Setup

Okay, now that iptables is a blank slate, lets get it set up to do [NAT](http://en.wikipedia.org/wiki/NAT).

```shell
# iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
# iptables -A FORWARD -i eth1 -j ACCEPT
# service iptables save
# chkconfig --level 345 iptables on
```

First, we set up a couple iptables rules, then save them, then make sure iptables is enabled to start on boot.

## Configure network switches

This is a very important step - xCat will expect to have SNMP read access to the community "public" so it can map from switch ports to nodes.  However, because your hardware will almost certainly differ, the best I can do is refer you to you own switch's documentation.  In my case I've set the switches up to send SNMP traps to the keepalived address.  The benefit of this is that if I'm running dual master nodes, it will get to the right place no matter who actually holds that IP address.  However, a setup like this will introduce some complexity later in the configuration.  If you'd rather avoid that complexity, simply set up two nodes as gateways sharing the keepalived address, but have only one run xCat and send SNMP traps to that node.

## Miscellaneous Configuration

This is the time to do any other configuration you'd like.  For example, NTP, syslog, or increasing maximum parameters (per [this section of the sumavi guide](http://sumavi.com/sections/kernel-parameters)).  In my case I've only done NTP (which is somewhat outside the scope of this walkthrough), so I wont be covering them.  I also like to have the man pages handy on any machine I work on, so I install those:

```shell
# yum install man man-pages
```

# Conclusion

In this section I covered rather a lot of the basic configuration of a master node - disabling SELinux, network setup, installing keepalived and making your node as a gateway.  If you're walking through these in sequence, now might be a good time to grab a breather and a drink.  But there will be other steps that take time and can run unattended, so hold off on that meal run!

In the next section, I'm going to be covering actually installing xCat.
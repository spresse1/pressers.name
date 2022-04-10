---
title: "Configuring Cisco 2900XL Switches via TFTP (and alongside xCat)"
date: 2012-09-11 01:36:59
slug: "configuring-cisco-2900xl-switches-tftp-and-alongside-xcat"
categories:
  - "ACM"
  - "ACM Cluster"
---

As part of my ACM cluster creation obsession, I wanted to make the Cisco 2900XL switches we have autoconfigure.  I'm not terribly familiar with how these switches operate and, rather than reconfigure all of them at once, I'd much rather be able to reboot (reload, in cisco parlence) them and have them come up with my new, clean config.

Fortunately for me, Cisco thought of a situation like this when building the software for these switches.  According to [this page from their instruction manual](http://www.cisco.com/en/US/docs/switches/lan/catalyst2900xl_3500xl/release12.0_5_wc5/swg/swsyst.html#wp1028392), if a switch boots and doesn't have an in-flash configuration file, it will DHCP/BOOTP for a network address, then attempt to TFTP one of several files - network-confg, cisconet.cfg, router-confg or ciscortr.cfg.

In my case, I'm running this next to xCat, so I already have a TFTP and DHCP servers running.  Furthermore, my switch was already set up in xCat to get a static address.  So all I really needed to do was put in the configuration file.  But how to generate one...

# Generating a Cisco Config

I chose to make my configuration file from the running configuration on my switches.  This seemed the simplest thing to do - get everything working as I wanted it, then save that configuration.  So here is how to get the running config from a Cisco switch:

```shell
Switch>enable
Switch#show running-config 
Building configuration...

Current configuration:
[output truncated]
```

You should be able to copy-paste this to one of the files I mentioned above (I used cisconet.cfg), remove any switch-specific information (specifically the IP address) and put it in the root tftp directory (/tftpboot, in my case).  The switches will then be able to self-configure using it.

# Configuring a switch to use DHCP configuration

The Cisco switches prefer local configuration over remote configuration.  The best way to make them fully configurable via the network is to completely remove all local configuration:

```shell
Switch>enable
Switch#dir
Directory of flash:/
  2  -rwx     1644046   Apr 04 2000 00:29:33  c2900XL-c3h2s-mz-120.5-XU.bin
  3  -rwx      105961   Apr 04 2000 00:29:33  c2900XL-diag-mz-120.5-XU
  4  drwx        6784   Apr 04 2000 00:29:34  html
111  -rwx         286   Jan 01 1970 00:00:14  env_vars
112  -rwx         660   Mar 01 1993 01:41:16  vlan.da
t114  -rwx        2961   May 11 1993 22:58:01  config.text

3612672 bytes total (833024 bytes free)
Switch#delete config.text
Switch#reload

System configuration has been modified. Save? [yes/no]: no
Proceed with reload? [confirm]
```

This block removes the active configuration and reboots the switch.  Now lets watch the xCat logs to make sure everything happens as we expect:

```shell
# tail -f /var/log/messages
Sep 13 15:49:11 cluster dhcpd: DHCPDISCOVER from 00:02:b9:94:20:c0 via eth1
Sep 13 15:49:11 cluster dhcpd: DHCPOFFER on 172.16.0.5 to 00:02:b9:94:20:c0 via eth1
Sep 13 15:49:11 cluster dhcpd: DHCPREQUEST for 172.16.0.5 (172.16.0.2) from 00:02:b9:94:20:c0 via eth1
Sep 13 15:49:11 cluster dhcpd: DHCPACK on 172.16.0.5 to 00:02:b9:94:20:c0 via eth1
Sep 13 15:49:14 cluster in.tftpd[20563]: RRQ from 172.16.0.5 filename eth-switch1.cfg
Sep 13 15:49:14 cluster in.tftpd[20564]: RRQ from 172.16.0.5 filename eth-switch1.cfg
```

Yes, it spits out rather a lot of junk.  In any case, it takes the switch about 1.5 minutes to completely reboot and if you see these messages in your log, you're all set.

# Fetching Config via TFTP

One thing I thought would be particularly nice for this setup was the ability to get the configuration of the switches via the network.  The cisco [2900xl manual](http://www.cisco.com/en/US/docs/switches/lan/catalyst2900xl_3500xl/release12.0_5_wc5/swg/swsyst.html#wp1028392) mentions the ability to do this, but I needed to get it to work with xCat.  In order to do this, I needed to specify files that DHCP should instruct the switch to download.  XCat doesn't seem to have a way to do this in the table format (though I'd love to be wrong about this).  However, the makedhcp man page says:

```shell
       [-s statements]
                   For the input noderange, the argument will be interpreted
                   like dhcp configuration file text.
```

Which lets me do exactly what I want.  Best of all, this data is preserved over all makedhcp operations, until I again specify a -s option.  So I ran the following:

```shell
makedhcp eth-switch1 -s 'supersede server.filename = \"eth-switch1.cfg\"; supersede server.next-server = [Hex encoded address of tftp server];
```

And thats it!  Now when I boot this switch, it fetches the eth-switch1.cfg file from my tftp server and uses that to self-configure.
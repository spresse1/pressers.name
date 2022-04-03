---
title: "Building the ACM VM Cluster, Part 10: Operating system image build"
date: 2012-12-15 18:40:42
slug: "building-acm-vm-cluster-part-8-operating-system-image-build"
categories:
  - "ACM"
  - "ACM Cluster"
---

Now that we're done with network configuration.  Now, lets actually build an operating system to use on the nodes!

# Lets go ISO Huntin'!

The first step in building operating system install images is to get the full operating system images.  Not netboot, but a fully installable version.  For CentOS the [mirrors page](http://www.centos.org/modules/tinycontent/index.php?id=30) is a good place to start your hunt.  Personally, I downloaded both DVD images (CentOS-6.3-x86_64-bin-DVD1.iso and CentOS-6.3-x86_64-bin-DVD2.iso), though I suspect that simply the minimal image will cover it.

# Import Install Media

Next, we have to import the install media to xCat's NFS filesystem.  To do this, we'll use the `copycds` command.  `copycds` takes as arguments simply the ISOs you want to import:

```shell
# copycds CentOS-6.3-x86_64-bin-DVD1.iso CentOS-6.3-x86_64-bin-DVD2.iso
```

Sometimes copycds will tell you

```shell
Error: copycds could not identify the ISO supplied, you may wish to try -n <osver>
```

In which case your command will look more like

```shell
# copycds -n centos6.3 CentOS-6.3-x86_64-bin-DVD1.iso CentOS-6.3-x86_64-bin-DVD2.iso
```

# Set Root Password

You probably will never need to log directly on to a node using a password (and xCat is nice and sets up ssh keys for you),  but lets set the root password on the nodes anyway:

```shell
# tabch key=system,username=root passwd.password=[your password]
```

# Test Kickstarting

Now we've got everything set up to try installing a node.  Note that this will just be a very generic install.  However, this seems to be a good time to test this before we start getting complicated in terms of making images.

So lets set node001 to kickstart from the generic compute image:

```shell
# nodech node001 nodetype.os=centos6.3 nodetype.arch=x86_64 nodetype.profile=compute
# nodeset node001 install
```

This second line mail fail.  In this is the case, xCat wants you to boot up the node once so it can do autodiscovery (find the mac address).  Without this it cannot set up the TFTP server to properly boot the node.  I recommend that you boot all the nodes, let xCat do autodiscovery, set the nodes to install, then reboot them.

Assuming you've got discivery working and were able to set the node to install, boot the node.  Note that if your machines have remote power that is properly built into xCat (unlike mine), you'll probably also want to have them do the appropriate setup (bmcsetup, for example).  See this [sumavi page for more details on the chain setup](http://sumavi.com/sections/under-the-hood-of-the-xcat-service-image).

If all goes well, you ought to see something like this in `/var/log/messages`:

```shell
Sep 14 16:56:12 bosca in.tftpd[3188]: RRQ from 172.18.0.1 filename pxelinux.0
Sep 14 16:56:12 bosca in.tftpd[3188]: tftp: client does not accept options
Sep 14 16:56:12 bosca in.tftpd[3189]: RRQ from 172.18.0.1 filename pxelinux.0
Sep 14 16:56:12 bosca in.tftpd[3190]: RRQ from 172.18.0.1 filename pxelinux.cfg/00020003-0004-0005-0006-000700080009
Sep 14 16:56:12 bosca in.tftpd[3191]: RRQ from 172.18.0.1 filename pxelinux.cfg/01-00-e0-81-2b-44-75
Sep 14 16:56:12 bosca in.tftpd[3192]: RRQ from 172.18.0.1 filename pxelinux.cfg/AC120001
```

Which indicates that the node is booting.  If you then check /var/log/httpd/access_logs, you'll see:

```shell
172.18.0.1 - - [14/Sep/2012:16:33:42 -0400] "GET /install/autoinst/node001 HTTP/1.1" 200 13912 "-" "anaconda/13.21.176"
172.18.0.1 - - [14/Sep/2012:16:33:46 -0400] "GET /install/centos6.3/x86_64/images/updates.img HTTP/1.1" 404 317 "-" "anaconda/13.21.176"
172.18.0.1 - - [14/Sep/2012:16:33:46 -0400] "GET /install/centos6.3/x86_64/images/product.img HTTP/1.1" 404 317 "-" "anaconda/13.21.176"
172.18.0.1 - - [14/Sep/2012:16:33:46 -0400] "GET /install/centos6.3/x86_64/images/install.img HTTP/1.1" 200 136585216 "-" "anaconda/13.21.176"
172.18.0.1 - - [14/Sep/2012:16:34:35 -0400] "GET /install/centos6.3/x86_64/.treeinfo HTTP/1.1" 200 398 "-" "urlgrabber/3.9.1"
172.18.0.1 - - [14/Sep/2012:16:34:35 -0400] "GET /install/centos6.3/x86_64/.treeinfo HTTP/1.1" 200 398 "-" "urlgrabber/3.9.1"
172.18.0.1 - - [14/Sep/2012:16:34:35 -0400] "GET /install/centos6.3/x86_64/repodata/repomd.xml HTTP/1.1" 200 4136 "-" "CentOS (anaconda)/6.3"
172.18.0.1 - - [14/Sep/2012:16:34:35 -0400] "GET /install/centos6.3/x86_64/repodata/018dd5e8db1fe55ccd4fd96d3b1daaa5782b34d254cc7766a0eb9d1ac7e1be0d-primary.sqlite.bz2 HTTP/1.1" 200 4673840 "-" "CentOS (anaconda)/6.3"
172.18.0.1 - - [14/Sep/2012:16:34:37 -0400] "GET /install/centos6.3/x86_64/repodata/0dae8d32824acd9dbdf7ed72f628152dd00b85e4bd802e6b46e4d7b78c1042a3-c6-x86_64-comps.xml HTTP/1.1" 200 1186698 "-" "CentOS (anaconda)/6.3"
```

I've truncated the output here, just for length.  The install process pulls many dozens of files and, in the case of CentOS takes about 15-30 minutes.  Assuming all goes well, you'll be able to ssh into your test node.  If that went well, go on forward.  If not, some good places to look for hints are `/var/log/messages` and `/var/log/httpd/access_log`.  Worst to worst, use wireshark to see whats going on on the network. If you're stuck, the [xcat-users list](https://lists.sourceforge.net/lists/listinfo/xcat-user) is a great place to ask for help.  Be sure to be as detailed as you can be!
---
title: "Building the ACM Cluster, part 11f: ZFS on Linux"
date: 2012-12-16 23:59:22
slug: "building-acm-cluster-part-11f-zfs-linux"
categories:
  - "ACM"
  - "ACM Cluster"
---

[ZFS](http://www.oracle.com/technetwork/server-storage/solaris11/technologies/zfs-338092.html) is one of those pieces of software that is almost frighteningly good at what it does.  It has a whole slew of features that make it, for many uses, the perfect filesystem.  These include: deduplication, compression, data integrity guarantees (ZFS can detect and repair silent data corruption), copy-on-write architecture and a built in concept of RAID.  The only problem is that the source is under a license incompatible with the linux kernel, so it will never be kernel mainline.  There is, however, the [ZFS on linux](http://zfsonlinux.org/) project, which makes it easy to bring ZFS to several linux distributions.

# Building ZFS

Download the SPL and ZFS packages from the [ZFS on Linux](http://zfsonlinux.org/) homepage.

## Building SPL

The main ZFS package requires that parts of SPL (the Solaris portability layer) be installed before ZFS can be installed.  So lets start by untaring SPL.  At the time of writing, the most recent version is 0.6.0-rc12:

```shell
$ tar xf spl-0.6.0-rc12.tar.gz
```

Now, lets build the RPMs:

```shell
$ cd spl-0.6.0-rc12
$ ./configure
$ make rpm
```

This builds SPL RPMs required and leaves them in the current directory.  That was simple.

## Install spl-devel

Remember I said some of SPL had to be installed for ZFS to build?  The package that must be installed is called spl-devel.  Install it by running:

```shell
# rpm -i spl-modules-devel-0.6.0-rc12_3.6.9_1.el6.x86_64.rpm
```

# Building ZFS

Before you build ZFS, you'll want to install a couple of dependancies:

```shell
# yum install -y zlib-devel libuuid-devel
```

Alright now lets untar ZFS:

```shell
$ tar xf zfs-0.6.0-rc12.tar.gz
```

and run (almost) the same commands as before:

```shell
$ ./configure
$ QA_RPATHS=$[ 0x0002 ] make rpm
```

The QA_RPATHS setting was required on my machine in order to deal with ZFS creating some slightly weird paths in the package.  However, they didn't seem to cause any problems.  If it weirds you out, leave it off and see what happens - it may be a fluke of something on the machine I was building on.

# Finalization

Now that ZFS and SPL are built, copy the RPMs to your xCat head node, then [inject them into the package repository as before](/2012/12/15/building-acm-cluster-part-11b-kernel-rpm-build/).
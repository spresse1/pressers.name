---
title: "Building the ACM Cluster, Part 11b: Kernel RPM Build"
date: 2012-12-16 04:11:20
slug: "building-acm-cluster-part-11b-kernel-rpm-build"
categories:
  - "ACM"
  - "ACM Cluster"
---

If you haven't already done so, read and execute [Building the ACM Cluster, Part 11a: Setting up rpmbuild environment](/2012/12/15/building-acm-cluster-part-11a-setting-rpmbuild-environment/).

This article will be covering building a new kernel for CentOS and injecting it into xCat's local package repository.  I am covering this because later on we'll need to have a more recent kernel than CentOS comes with by default.  Xen specifically requires a later kernel.  However, when we build kernel modules, we'll want to be building against the same kernel version we're running.

# Kernel Spec

I've built a kernel spec based on that at ElRepo (downloadable at `kernel/el6/SPECS/` from any of [these mirrors](http://elrepo.org/tiki/Download)).  This builds a kernel package called kernel-ml.  This is so that it can coexist with the CentOS official kernel.  However, I have a different goal - I want to replace the kernel.  I've therefore created my own [branch on my GitHub](https://github.com/spresse1/acm-vm-cluster/blob/master/kernel/kernel-3.6.spec).  The only difference between this and the official specfile is that I've removed every instance of -ml so that the built RPM will replace the official kernel.  Copy this specfile into your rpmbuild/SPECS directory.

Now we need to acquire the linux source in .tar.bz2 form.  It is available from [kernel.org](http://www.kernel.org/pub/linux/kernel/).  You can download any 3.6 kernel you wish.  My spec file is (at the time of writing) set for kernel 3.6.9\.  If you wish to use a more recent kernel, there is a single line near the top to update.  Once you've downloaded your kernel of choice, put it in `rpmbuild/SOURCES`.  

Finally, you need configuration files for the kernel.  You can do one of two things - use [my configuration file](https://github.com/spresse1/acm-vm-cluster/blob/master/kernel/config-3.6.9) or build your own.  If you build your own, I recommend that you untar the source you downloaded and configure that, then copy the generated `.config`.  Whatever configuration file you use, it needs to be copied into 4 places - 

*   `rpmbuild/SOURCES/config-[KERNEL_VERSION]-i686`
*   `rpmbuild/SOURCES/config-[KERNEL_VERSION]-i686-NONPAE`
*   `rpmbuild/SOURCES/config-[KERNEL_VERSION]-x86_64`
*   `rpmbuild/SOURCES/config-[KERNEL_VERSION]-x86_64-NONPAE`

These files may all be the same configuration.  Once you have these in place, you're ready to build!

# Building the Kernel

Having a spec file makes building the kernel nice and easy:

```shell
$ rpmbuild -ba rpmbuild/SPECS/kernel-3.6.spec
```

Your computer will spin for a while, then the built RPM will appear in `rpmbuild/RPMS`.

# Injecting the Kernel

Although I'm discussing this process specific to the kernel, it is actually the same for any package you want to inject into your local xCat repository.  We'll be referring to this procedure in future package injections.

First things first - you have to do this on your management node.  So copy the RPMs from the machine you built them on to your management node.  xCat keeps its RPMs in two places for CentOS - `/install/[OS_VERSION]/x86_64/repodata` and `/install/[OS_VERSION]/x86_64/x86_64/repodata`, where OS_VERSION is something like centos6.3  So copy your RPM to both of these locations:

```shell
# cp [PACKAGE] /install/[OS_VERSION]/x86_64/Packages
# cp [PACKAGE] /install/[OS_VERSION]/x86_64/x86_64/Packages
```

Now that we have the files in the right place, we need to rebuild the repository.  The tool we use to do this is called, obviously enough, createrepo.  So run:

```shell
# createrepo -g /install/centos6.3/x86_64/repodata/*-x86_64-comps.xml /install/centos6.3/x86_64/
```

The `-g` option preserves the groups that are already in the repository.

And you now have built your own kernel and injected it into the repository.  From here I suggest reinstalling a node, so you can do future RPM builds on a node running your new kernel.
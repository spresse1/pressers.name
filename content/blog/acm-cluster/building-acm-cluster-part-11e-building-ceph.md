---
title: "Building the ACM Cluster, Part 11e: Building Ceph"
date: 2012-12-16 16:32:07
slug: "building-acm-cluster-part-11e-building-ceph"
categories:
  - "ACM"
  - "ACM Cluster"
---

[Ceph](http://ceph.com/) is a distributed storage engine.  It can be used in a whole number of different ways - for example, as a block device or an object store.  The current version is codenamed argonaut, hence the header image.

In the ACM cluster, we're using it as the storage engine for VMs.  This makes a lot of sense in our case, as the VMs are going to want to move from machine to machine and this stops them having to copy the disk image.  Ceph also has the advantage of being kernel-mainline, meaning that all the required bits for it are already built into the kernel and building it does not require patching the kernel at all.

# Building RPMs

Building the Ceph RPMs is very similar to the other RPM builds we've already done.  Ceph is extraordinarily kind and provides their own (working!) spec file.  So first off, download the Ceph [tar.bz2 from here](http://ceph.com/resources/downloads/).  Assuming you're using the same ceph 0.48-argonaut version I am, you'll then want to run

```shell
$  tar xvf ceph-0.48argonaut.tar.bz2 ceph-0.48argonaut/ceph.spec
```

to extract the spec file.  Now copy the spec file to `rpmbuild/SPECS` and the tar.bz2 to `rpmbuild/SOURCES`.

There is one dependency to Ceph that we can't satisfy out of the CentOS repositories.  The rados gateway portion of Ceph requires a fastcgi implementation.  We don't use it in our stack so what I've done is a bit of a hack.  I found it was simpler to just provide an RPM to satisfy this and then ignore the built package (that is, not inject it into the repository) and that this didn't cause any harm.  The missing package is called fcgi-devel.  It is available in Fedora EPEL (extra packages for enterprise linux) repository.  Because there are various other subdependancies, the easiest thing to do is [add EPEL](http://linux.mirrors.es.net/fedora-epel/6/i386/repoview/epel-release.html) to the machine we're building on.

```shell
# rpm -i 'http://linux.mirrors.es.net/fedora-epel/6/i386/epel-release-6-7.noarch.rpm'
```

This is one other good reason to have a machine we're building on that is easily wiped - we can add whole other repositories without really caring.

Now, lets build Ceph.

```shell
$ rpmbuild -ba rpmbuild/SPECS/ceph.spec
```

(Again, you may need the [magical "install dependencies" line from part 11a](/2012/12/15/building-acm-cluster-part-11a-setting-rpmbuild-environment/)).

Ceph will chew for a bit (longer than the kernel, less time than Xen), then spit out RPMs as before.  Inject them [as in part 11b](http://localhost:9090/2012/12/15/building-acm-cluster-part-11b-kernel-rpm-build/), and you're all set with Ceph!

There are two options for cleaning up before we continue:

1.  Remove EPEL  

    ```# rpm -e epel-release```

2.  Reinstall the node - Make sure you copy the built packages off it first!
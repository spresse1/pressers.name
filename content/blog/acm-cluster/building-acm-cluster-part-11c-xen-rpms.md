---
title: "Building the ACM Cluster, Part 11c: Xen RPMs"
date: 2012-12-16 04:24:34
slug: "building-acm-cluster-part-11c-xen-rpms"
categories:
  - "ACM"
  - "ACM Cluster"
---

Next up,  lets build RPMs of [Xen](http://xen.org/), a hypervisor.  Xen was chosen because on machines which do not have virtualization bits (like the cluster I'm building), Xen will do paravirtualization, which is still somewhat quick.Xen also has the concept of clustering and shifting VMs between instances - an important feature in a VM cluster!

# Xen Spec Files

CentOS 6 no longer has support for Xen.  CentOS decided that they were going to put their weight behind QEMU/KVM as the virtulization solution and thus stopped distributing and supporting Xen.  There are a few third party sites out there hosting packages. But, frankly, I am sufficiently paranoid to want to build them myself.  I also could not find a freely available spec file.  So I [wrote my own for Xen](https://github.com/spresse1/acm-vm-cluster/blob/master/xen/xen.spec).  Hopefully the fact that I simply use the official Xen source and a spec file that is very simple and easy to examine will satisfy those who are as paranoid as I am.

# On to Building the RPM

1.  Download [a copy of my spec file](https://raw.github.com/spresse1/acm-vm-cluster/master/xen/xen.spec).  As before put it in `rpmbuild/SPECS`.
2.  Download [a copy of Xen](http://xen.org/products/downloads.html).  At the time of writing, my spec file is designed for Xen 4.2.0, which can be [downloaded here](http://bits.xensource.com/oss-xen/release/4.2.0/xen-4.2.0.tar.gz).  Put this in `rpmbuild/SOURCES`.

If you need to update my spec file to a later version of Xen, it should be as simple as change the `Source:` and `Version:` lines of the spec file to reflect the new version number.  Then, run, similarly to before:

```shell
$ rpmbuild -ba rpmbuild/SPECS/xen.spec</pre>
```

(You will probably need to install dependencies, as [I covered in part 11a of this series](/2012/12/15/building-acm-cluster-part-11a-setting-rpmbuild-environment/).)

It'll chew for a while (seriously, Xen takes longer than the kernel), but then you'll end up with Xen RPMs in `rpmbuild/RPMS`.  Congrats, you have a Xen package!  Inject it as before ([the end of part 11b](/2012/12/15/building-acm-cluster-part-11b-kernel-rpm-build/)) and move on.
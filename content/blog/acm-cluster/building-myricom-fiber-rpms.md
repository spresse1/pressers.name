---
title: "Building the ACM Cluster, Part 11d: Building Myricom fiber RPMs"
date: 2012-12-16 05:49:26
slug: "building-myricom-fiber-rpms"
categories:
  - "ACM"
  - "ACM Cluster"
---

Welcome back to my ongoing series on building the JHUACM VM cluster.  In this part, I'm going to be focusing on building the RPM driver for the Myricom fiber cards that were given to us with the cluster.  Unfortunately the drivers for this are closed source.  However, through my connections to physics, I was able to get source code to build from.  In short, if you're here looking for drivers, you're out of luck - go talk to Myricom.

The specific hardware we have is driven by the mx2g driver, so that is what I'll be working on.

# Down the Rabbit Hole

The first thing I did when I got the tarball of the driver source was try to build the rpm.  The normal RPM build process is to copy the source tarball and a spec file into rpmbuild.  With these, it was some convoluted, undocumented and inflexible process.  In short, the process was to run "make rpm", copy a magic folder somewhere magical, and then run rpmbuild against the spec file.  This also deliberately limited the install location to /opt/mx, which I thought was a poor practice.

So I rewrote the spec file.  Since this is entirely my work, I feel comfortable releasing it publicly, even though the rest of the source isn't.  This spec file is therefore released without restriction.  In order to make sure you get the most recent version, please get the file [from my github](https://github.com/spresse1/acm-vm-cluster/blob/master/mx/mx.spec).

I've done my best to retain parity with the Myricom spec file.  However, the advantage of this spec file is that it installs the driver in sane, normal places.

To build the Myricom MX2 driver with this file, copy the spec file to `rpmbuild/SPECS` and the source tarball (mx2g_1.2.16.tar.gz in this case) to `rpmbuild/SOURCES`.  Then build it just like you were building any other RPM.

# Build Process

The build process here is much the same as the process documented elsewhere in this setup document.  Copy [the spec file](https://github.com/spresse1/acm-vm-cluster/blob/master/mx/mx.spec) to `rpmbuild/SPECS` and the source tarball to `rpmbuild/SOURCES`.  You'll also want the patch [I made available on GitHub](https://github.com/spresse1/acm-vm-cluster/blob/master/mx/mx-update-to-3.x.patch) to fox the mx2g source for linux 3.x kernels.  Then run

```shell
$ rpmbuild -ba mx.spec
```

Finally, [inject it into the package repository as before](/2012/12/15/building-acm-cluster-part-11b-kernel-rpm-build/).
---
title: "Building the ACM Cluster, Part 11g: OpenAFS RPM Build"
date: 2012-12-17 05:25:42
slug: "building-acm-cluster-part-11f-openafs-rpm-build"
categories:
  - "ACM"
  - "ACM Cluster"
---

[OpenAFS](http://www.openafs.org/) is the open source version of the AFS - a file system developed at Carnegie-Mellon University.  AFS has a global, DNS-based address space.  It also has a ton of nice features with respect to allowing users to create and control their own groups and much more granular permissions.  All in all it seems to be a good way to get data into a cluster and to allow users to store and manage documents in a reliable format.

# Building OpenAFS

I've saved building OpenAFS for last because it is somewhat more complicated than the other RPM builds we've done so far, primarily due to some messiness with kernel versions.  Spcifically, the kernel interfaces that OpenAFS-1.6.1 (the current Linux release) were changed from the 2.6 to the 3.x branch.  OpenAFS has sources that are patched for this, but hasn't released them yet.

## Getting Source

So, to get the proper source, we're going to have to get them from git.

```shell
$ git clone git://git.openafs.org/openafs.git
```

We then want to advance to the current HEAD revision of the branch named "openafs-stable-1_6_x".

```shell
$ cd openafs && git checkout openafs-stable-1_6_x
```

Finally, you'll want the OpenAFS [docs tar.bz2, available here](http://www.openafs.org/release/latest.html).  At the time of writing this is [openafs-1.6.1-doc.tar.bz2](http://www.openafs.org/dl/openafs/1.6.1/openafs-1.6.1-doc.tar.bz2).

## Building Source

First things first - we need to regenerate the source tree to reflect the fast that it has moved machines:

```shell
$ ./regen.sh
```

Now comes some of the tough part - we're going to work through the packaging scripts OpenAFS uses to build RedHat RPMs (they happen to work on CentOS too).

```shell
$ cd src/packaging/RedHat/
```

The next step is to build a source RPM.  This is an RPM designed to enable the building of a binary RPM.  OpenAFS provides a script for doing this - makesrpm.pl - but it requires two tarballs - one of the source and one of the docs.  We have one of the docs (we downloaded it earlier, remember?), so lets build one of the source.

```shell
$ cd ~
```

We need to fake the entire structure of the OpenAFS source tarball.  This means our source folder needs to be named openafs-1.6.1

```shell
$ mv openafs openafs-1.6.1
```

Now we have to create some files in the tarball (and remove all the git history, while we're at it...)

```shell
$ echo "1.6.1" > openafs-1.6.1/.version
$ rm -rf openafs-1.6.1/.git<
```

Now, lets actually create our tarball.

```shell
$ tar cjf openafs-1.6.1-src.tar.bz2
```

Now comes the tough part.  We have to use the RedHat scripts OpenAFS provides to build a source RPM.  the SRPM can then be used to build a binary RPM.

```shell
$ cd openafs-1.6.1/src/packaging/RedHat/
$ ./makesrpm.pl ~/openafs-1.6.1-src.tar.bz2 ~/openafs-1.6.1-doc.tar.bz2
```

(I've assumed you but both tarballs in your home directory.  If not, adjust the paths.)  This will spit out a file named `openafs-1.6.1-1.src.rpm`.  We can now use this to build the binary packages with:

```shell
$ rpmbuild --rebuild openafs-1.6.1-1.src.rpm
```

This will likely require some dependencies, use:

```shell
# yum install -y `rpmbuild --rebuild openafs-1.6.1-1.src.rpm 2>&1 | grep 'is needed by'`
```

to install them.

The build will chew for a while, then spit out binary packages.  Copy these to your management node and [inject them as before](/2012/12/15/building-acm-cluster-part-11b-kernel-rpm-build/).  Congratulations, you just built OpenAFS!
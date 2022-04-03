---
title: "Building the ACM Cluster, Part 11a: Setting up rpmbuild environment"
date: 2012-12-15 20:14:28
slug: "building-acm-cluster-part-11a-setting-rpmbuild-environment"
categories:
  - "ACM"
  - "ACM Cluster"
---

Up to this point, we haven't built any custom software for the cluster.  I've tried very hard to use mostly off the shelf software.  However, this has to change.  Several of the major components we're going to use (xen, the fiber card driver, ceph) are not available in the CentOS repositories (or are too old).  So we're going to build them ourselves.

However, rather than build them on a node-by node basis (which would make a single install hours long...), we're going to build packages.  CentOS uses the rpm package format to distribute prebuilt software.  So we'll be building RPMs.

# Where do I build RPMs?

Many resources recommend not building RPMs as root.  This is quite sensible if you're doing it on a machine that can't easily be rebuilt - that way you can't accidentally overwrite an important file.  However, since you 

# Installing rpmbuild

The primary tool used to build rpms is called, obviously enough rpmbuild.  We also need a package called rpmdevtools to get the proper environment set up.  Lets get them installed:

```shell
# yum install -y rpmbuild rpmdevtools
```

# Set up the Basic Environment

Run 

```shell
$ rpmdev-setuptree
```

This creates a file tree that looks something like:

```shell
$ ls rpmbuild/
BUILD  RPMS  SOURCES  SPECS  SRPMS
```

Each of these directories starts off empty, but here is what will eventually go in each:

*   BUILD - the directory the rpmbuild tool works in.  You'll probably never interact directly with this directory.
*   RPMS - the output directory, where rpmbuild will put the packages RPMs
*   SOURCES - the input files needed to build the RPMs.  Typically a tarball plus perhaps some other supporting files.
*   SPECS - A directory which contains the files that tell rpmbuild how to build and package the software.  We'll get more into spec files much later.
*   SRPMS - SRPMS are the source packages used to build RPMs.  We probably won't interact with this directory, since we only intend to redistribute binaries.

# A Useful Command

One thing that you'll often find in the process of building RPMs is that rpmbuild will tell you you're missing dependencies.  Rather than going through and manually installing each of the dependencies, you can use the following to automatically install the dependencies.

```shell
$ yum install -y `rpmbuild -ba [SPECFILE] 2>&1 | grep 'is needed by' | awk '{print $1}' | xargs`
```

where `[SPECFILE]` is the spec file you're attempting to use.

# Next up: Building packages

This part on building required RPMs is going to be long and so is split into several posts.  I'll update this section with links to the other posts as we go.
---
title: "Building the ACM VM Cluster, Part 4: xCat Install"
date: 2012-09-09 13:19:43
slug: "building-acm-vm-cluster-part-4-xcat-install"
categories:
  - "ACM"
  - "ACM Cluster"
---

In [part 3 of this series](/2012/09/08/building-acm-vm-cluster-part-3-keepalived/), we got the management node set up to route traffic and generally properly configured.  Now its time to actually install xCat!

# Choices

Many xCat guides recommend downloading the RPMs and manually installing those.  The benefit of this route is that you need no network connection to your management node for this setup.  However, I prefer to have a simple upgrade path.  I also know my cluster will continuously be connected to the internet, so I don't need an offline configuration.  Therefore I'm going to use the xCat repos to do the install.  For this case, refer to this [piece of xCat documentation](http://sourceforge.net/apps/mediawiki/xcat/index.php?title=XCAT_iDataPlex_Cluster_Quick_Start#Option_2:_Prepare_to_Install_xCAT_Directly_from_the_Internet-hosted_Repository) if you need more detail.

# Set up xCat repos

First we need wget so we can grab files from the xCat website:

```shell
# yum install wget
```

Now lets make sure we put the files in the right place:

```shell
# cd /etc/yum.repos.d
```

List the directory and make sure you don't already have the xCat repos.  If you do, then skip the next step.  If you don't already have the xCat repos, run:

```shell
# wget http://sourceforge.net/projects/xcat/files/yum/stable/xcat-core/xCAT-core.repo
```

You'll also need the xCat dependencies repo.  This depends on your operating system.  Find it on [this page](http://sourceforge.net/projects/xcat/files/yum/xcat-dep/) if you're not using CentOS.  If you are using CentOS, the following command should work:

```shell
# http://sourceforge.net/projects/xcat/files/yum/xcat-dep/rh6/x86_64/xCAT-dep.repo/download
```

# Install xCat

and now the moment you've been waiting for!  Lets actually install xCat:

```shell
# yum clean metadata
# yum install xCAT
```

Now might be a good time to go grab that meal you've been thinking about.  This will take a bit to install.

# Simple Test

Lets do a quick test to make sure xCat installed okay:

```shell
# bash
# nodels
```

If you see no output, your install of xCat is okay and you should continue to the next section. (Note that I called a new shell to reload the environment) Alternatively, run:

```shell
# . /etc/profile.d/xcat.sh
```

# Next Time...

Next up is configuring xCat.  Good thing you had time to grab a meal - this next section will take a while and doesn't have any long breaks.
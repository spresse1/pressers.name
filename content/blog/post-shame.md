---
title: "The Post of Shame"
date: 2021-01-02 14:13:02
slug: "post-shame"
categories:
  - "Infrastructure"
---

So this site has been down since at least July 9, 2019 (according to my email). And the reasons were pretty simple -- and dumb. This post is going to be a sort of post-mortem on why it failed and what the fixes were. And (hopefully) it'll include some lessons learned.

# About the Site

This site runs on apache2 on a debian-stable server. The underlying site is written in [Django](https://www.djangoproject.com/). The entire site is supposed to be self-maintaining. This happens via a combination of Debian's [unattentded-upgrades](https://wiki.debian.org/UnattendedUpgrades) capabilities and a homebrew [django-autoupdate script](https://github.com/spresse1/pressers.name/blob/master/django-autoupdate). Django, in turn, is backed by a MySQL database.

In order to be able to cleanly attempt upgrades,

# So What Happened?

Simply put, Debian Buster released ([on July 6, 2019](https://en.wikipedia.org/wiki/Debian_version_history#Debian_10_(Buster))) and I wasn't prepared. This release upgraded python. Normally that's not a big issue. Except that I had hard-coded the python version in the site configuration file:

```xml
<IfModule mod_ssl.c>  
    <VirtualHost *:443>  
        ServerName pressers.name:443  
        DocumentRoot /var/www/html  
        WSGIDaemonProcess pressers_name python-path=/var/www/pressers.name:/var/www/pressers.name/lib/python3.5/site-packages  
       WSGIScriptAlias / /var/www/pressers.name/pressers_name/wsgi.py

[ snip ]

    </VirtualHost>  
</IfModule>
```

See the `WSGIDaemonProcess` line? And how I hardcoded python3.5 into that? The Debian Buster upgrade brought with it python3.7, so Apache was trying to run the WSGI script using non-existent files. D'oh!

The (temporary) fix is simple: Adjust the hardcoded path to point to python3.7, which came with Buster.

# The Permanent Fix

Is just two lines, added to [the environment build](https://github.com/spresse1/pressers.name/commit/28249500a9af49f0775df1853871451265f3c316):

```shell
PYPATH=$(ls -d lib/python* | sort | tail -n 1)  
ln -s "$(basename $PYPATH)" "lib/python"
```

These two lines create a "python" directory in lib (in the virtualenv) which points to the latest python. Unlike the typical python directory in lib, this one doesn't include the version number, which will let us put it in the apache configuration file -- and to not have to update the apache config when the python version changes!

# Root Cause

Root cause is a hardcoded path that was no longer valid. This is a pretty simple, dumb mistake and I should have seen it coming. So the biggest lesson: make sure you're not hardcoding things!

There's also a second lesson here: Don't make assumptions about the OS under you maintaining backwards compatibility.  When I first built this site, CI/CD pipelines were not in as common use. Building something that spun up a fresh webserver to test the site every night would have been a huge effort. So I didn't. Today CI/CD pipelines are much more featureful and robust -- maybe it's time I look at one for this site.

# Long Term

In fixing this and updating other things that had had minor failures, I discovered that the engine I'm using to run this blog (zinnia) is now a dead project. It will not be updated to work with Django 3, which limits this site to working with Django 2\. Django 2 is End of Life on 01 April, 2022\. So I have until then to move things off...

In the time since I set this site up, I've become a fan of building simple sites using things like [pelican](https://blog.getpelican.com/). This site doesn't have anything truly interactive; why back it with something that takes as much maintenance and effort as Django if I am not taking advantage of those capabilities?

So I will likely move towards something like that for building sites. HTML will never go end of life out from under me.
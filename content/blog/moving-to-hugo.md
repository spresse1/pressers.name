---
title: "Moving to Hugo"
date: 2022-03-13T15:55:40+01:00
draft: true
---

# Setting this up on hugo

Converting ot use hugo because zinnia is dead

# Install Hugo

```shell
# apt-get install hugo
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  libfwupdplugin1 linux-headers-5.13.0-23 linux-headers-5.13.0-23-generic linux-image-5.13.0-23-generic linux-modules-5.13.0-23-generic linux-modules-extra-5.13.0-23-generic
Use 'sudo apt autoremove' to remove them.
The following additional packages will be installed:
  libsass1
The following NEW packages will be installed:
  hugo libsass1
0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
Need to get 11.5 MB of archives.
After this operation, 52.0 MB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://us.archive.ubuntu.com/ubuntu impish/universe amd64 libsass1 amd64 3.6.5-1ubuntu1 [773 kB]
Get:2 http://us.archive.ubuntu.com/ubuntu impish/universe amd64 hugo amd64 0.80.0-6 [10.7 MB]
Fetched 11.5 MB in 2s (4,613 kB/s)
Selecting previously unselected package libsass1:amd64.
(Reading database ... 291399 files and directories currently installed.)
Preparing to unpack .../libsass1_3.6.5-1ubuntu1_amd64.deb ...
Unpacking libsass1:amd64 (3.6.5-1ubuntu1) ...
Selecting previously unselected package hugo.
Preparing to unpack .../hugo_0.80.0-6_amd64.deb ...
Unpacking hugo (0.80.0-6) ...
Setting up libsass1:amd64 (3.6.5-1ubuntu1) ...
Setting up hugo (0.80.0-6) ...
Processing triggers for man-db (2.9.4-2) ...
Processing triggers for libc-bin (2.34-0ubuntu3.2) ...
#
```

Next initialize the hugo site:

```shell
$ hugo new site pressers.name
Congratulations! Your new Hugo site is created in ~/Projects/pressers.name.

Just a few more steps and you're ready to go:

1. Download a theme into the same-named folder.
   Choose a theme from https://themes.gohugo.io/ or
   create your own with the "hugo new theme <THEMENAME>" command.
2. Perhaps you want to add some content. You can add single files
   with "hugo new <SECTIONNAME>/<FILENAME>.<FORMAT>".
3. Start the built-in live server via "hugo server".

Visit https://gohugo.io/ for quickstart guide and full documentation.
$
```

# Theme

Add a theme:

```shell
 git submodule add https://github.com/zerostaticthemes/hugo-whisper-theme themes/whisper
Cloning into '/home/steve/Documents/Projects/pressers.name/themes/whisper'...
remote: Enumerating objects: 685, done.
remote: Counting objects: 100% (38/38), done.
remote: Compressing objects: 100% (29/29), done.
remote: Total 685 (delta 11), reused 25 (delta 6), pack-reused 647
Receiving objects: 100% (685/685), 2.17 MiB | 714.00 KiB/s, done.
Resolving deltas: 100% (275/275), done.
$  echo theme = \"whisper\" >> config.toml
```

# Content



# Tweaking URLs to include date codes

From [the Hugo documentation](https://gohugo.io/content-management/urls/#permalinks-configuration-example)

```toml
[permalinks]
    'blog' = '/:year/:month/:day/:slug'
```

This alters URLs so that all the blog posts show up at the same URL as they used to. This allows moving without breaking any links. I also have to make sure I get the slug set correctly for each...

# Extensions

## Email cloaking

```shell
$ git submodule add https://github.com/martignoni/hugo-cloak-email.git themes/hugo-cloak-email
Cloning into '/home/steve/Documents/Projects/pressers.name/themes/hugo-cloak-email'...
remote: Enumerating objects: 91, done.
remote: Total 91 (delta 0), reused 0 (delta 0), pack-reused 91
Receiving objects: 100% (91/91), 34.11 KiB | 2.13 MiB/s, done.
Resolving deltas: 100% (35/35), done.
```

Add add hugo-cloak-email as the leftmost entry in the themes.

```diff
--- config.toml 2022-03-15 21:35:30.520928238 +0100
+++ config.toml 2022-03-15 21:35:03.908571845 +0100
@@ -1,7 +1,7 @@
 baseURL = "https://pressers.name/"
 languageCode = "en-us"
 title = "The Electronic Press"
-theme = [ "hugo-cloak-email", "whisper" ]
+theme = "whisper"
 
 [permalinks]
     'blog' = '/:year/:month/:day/:slug'
```

## Social Metadata (Requires theme integration)

```shell
$ git submodule add https://github.com/msfjarvis/hugo-social-metadata.git themes/hugo-social-metadata
Cloning into '/home/steve/Documents/Projects/pressers.name/themes/hugo-social-metadata'...
remote: Enumerating objects: 52, done.
remote: Counting objects: 100% (52/52), done.
remote: Compressing objects: 100% (25/25), done.
remote: Total 52 (delta 18), reused 47 (delta 13), pack-reused 0
Receiving objects: 100% (52/52), 12.25 KiB | 6.13 MiB/s, done.
Resolving deltas: 100% (18/18), done.
```

```diff
--- config.toml 2022-03-15 21:43:01.851111250 +0100
+++ config.toml 2022-03-15 21:41:12.557595136 +0100
@@ -1,7 +1,7 @@
 baseURL = "https://pressers.name/"
 languageCode = "en-us"
 title = "The Electronic Press"
-theme = [ "hugo-social-metadata", "hugo-cloak-email", "whisper" ]
+theme = [ "hugo-cloak-email", "whisper" ]
 
 [permalinks]
     'blog' = '/:year/:month/:day/:slug'
```

## Hugo-redirect

Not really needed with aliases and would be a massive pain, since it requires adding a file for every redirect.

Probably easier to add a general redirect before 404, if I want that.
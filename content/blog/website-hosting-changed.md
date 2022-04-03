---
title: "Website hosting changed"
date: 2022-04-03T15:55:40
draft: true
---

So I just changed the hosting for my website. It's now hosted using Hugo and on GitHub pages. Long story short, if anything seems broken, [Contact me]({{< ref "/contact.md" >}})

This is because Django2 support is coming to an end and Zinnia (the blogging engine I used with Django) never got support to move it to Django3.

Honestly, the technical of this is not that interesting.

# Some improvements

I took the opportunity to make some improvements to the theme I'm using. It's now more responsive and (hopefully) more helpfully responsive as screen size shifts.

# Why Hugo?

Mostly because this is a static site. I don't use any non-static features on my website, so why use (and pay for) something more complicated than I need?

As a side effect, this reduces the amount of software I need to keep up to date, removes two daily cron job emails, and shuts down a web server.

I also like writing in Markdown. I keep my personal notes in Markdown when working on projects, so this will make it much easier to convert them over to posts -- hopefully meaning I won't have years-long spells without posting any more!

Hugo is also nice because it's written in Go. Normally I object from a security perspective, but for an offline tool like this where I simply need it to be able to regenerate the output, it's perfect. It doesn't matter what happens to the Hugo project; I'll be able to rebuild this website and keep adding to it. And after having Zinnia silently end support and force me to move away from it, this seems like a major feature to me.

# Still to come

* Flesh out "Publications and Appearances"
* More theme improvements?

# Some Hugo technical details

I made some configuration changes to the base Hugo configuration in order to make the site do everything I want. Here they are.

## Tweaking URLs to include date codes

My old site used date codes as part of post URLs. While I would probably just use a slug these days (and would put all blog content under `/blog` instead of `/`), I don't want to break URL backwards compatibility. So let's turn on date-coded URLs for things in the `/blog` folder (and remove the `/blog` prefix).

From [the Hugo documentation](https://gohugo.io/content-management/urls/#permalinks-configuration-example)

```toml
[permalinks]
    'blog' = '/:year/:month/:day/:slug'
```

I did consider only setting this up for old posts and using a new scheme for new posts. But in the end, it's just a URL format and it wasn't worth figuring out how to have both appear at the same time. I could also have used aliases, but without a real server and HTTP 301 redirects, that seemed too likely to cause problems.

## Extensions

I added a couple of extensions for minor functionality

### Email cloaking

One of reasons I don't like having a dynamic site is that I keep getting spam via my contact form. Which is fair, since I don't have a captcha on there. But nonetheless, something which lets people easily reach me without creating a lot of spam sounds great. So let's add the [`hugo-cloak-email` module](https://github.com/martignoni/hugo-cloak-email):

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
-theme = [ "hugo-cloak-email", "pressers.name" ]
+theme = "pressers.name"
 
 [permalinks]
     'blog' = '/:year/:month/:day/:slug'
```

### Social Metadata

This one requires theme integration. In order to make it possible for pages to appear in specific and pretty ways on social media, let's add the [`hugo-social-metadata` module](https://github.com/msfjarvis/hugo-social-metadata):

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
-theme = [ "hugo-social-metadata", "hugo-cloak-email", "pressers.name" ]
+theme = [ "hugo-cloak-email", "pressers.name" ]
 
 [permalinks]
     'blog' = '/:year/:month/:day/:slug'
```
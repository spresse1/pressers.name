Website Sources
===============

This repository contains much of the source of my website. See 
[pressers.name](https://pressers.name) for the actual website.

Deployment of the site is based on [Hugo](https://gohugo.io/). Mostly because
bringing in the existing theme was straightforward and I like writing
in markdown.

Deployment
----------

Is currently manual via the `deploy.sh` script, which looks for a `.config`
file in the current working directory.

I'd like to move this to something automatic (eg: GitHub workflow or git-hook
based) but haven't had time. I also mean to put together something to run as
a cron job on hosted infrastructure to pull/rebuild the website. But again,
haven't had time.

Other utilities
---------------

* `run_local_server.sh` will run the hugo development server with drafts enabled
  so that changes may be validated before being pushed. Not that all links
  should be relative, or it'll try to pull stuff from the live site instead.
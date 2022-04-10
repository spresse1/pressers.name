---
title: "Notes: Adding libGL.so to android emulator images"
date: 2012-12-22 05:04:31
slug: "notes-adding-libglso-android-emulator-images"
---

Earlier this evening, I was playing with Android emulators.  Specifically, I was playing with emulating an application which uses libGL.  On emulator boot, I was getting messages like:

```
libGL.so: cannot open shared object file: No such file or directory
```

It turns out that though no version of the binary is included in the default ADK, the correct one can simply be linked in.  On my Debian Wheezy/testing machine, this was done as:

```shell
$ ln -s /usr/lib/x86_64-linux-gnu/libGL.so.1 ~/android-sdk-linux/tools/lib/libGL.so
```

Which also has the advantage that it requires no privileges.

If you need to find the .proper libGL.so file, consider using:

```shell
$ find / -name libGL.so* 2>/dev/null
```
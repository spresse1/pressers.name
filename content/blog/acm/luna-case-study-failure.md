---
title: "Luna: A Case-Study in Failure"
slug: "luna-case-study-failure"
date: 2012-09-08 17:23:13
categories:
  - "ACM"
---

I intended to make the first post here be about the technology under the site and how to set up a similar site.  I will still write that one, but in the meantime a much more interesting problem has come up and I wish to share it with you.

This post is about the various issues, both human and machine that lead to the failure of Luna, the [JHU ACM](http://acm.jhu.edu/)'s Xen virtual machine server.  I'm going to start with an examination of what lead up to the failure, continue with details on the failure mode of this machine, detail my investigation of the failure, and finish with the recovery of the machine and data.

Before I get any further into this post, I wish to make absolutely clear that I am not writing this to assign blame.  This post is meant to be informational, to examine issues that can lead to a catastrophic failure and even to suggest solutions.  However, I believe that all involved were operating as best they knew how and it would therefore be unfair to blame anyone.

# Luna, as built

Supermicro PDSMi Motherboard

2x Intel Core 2 @ 2.13GHz

2 Gigabytes of RAM @ 533Mhz

Various Disks, housing several Xen virtual disks in an LVM raid-1 partition

# Contributors to Failure

It is my view that there were three main contributors to the failure of this machine: Failure to maintain institutional knowledge, failure to properly monitor hardware and (obviously) hardware failure.

## Failure to Maintain Institutional Knowledge

Anyone who has worked with me on any complex project in the last couple of years knows that I can be a little bit nuts about documenting things.  In previous jobs, I have picked up systems which have no documentation other than the state they are running in, code that has no documentation and just generally things where the only way one would know about them is if one wrote them.  This is in addition to the numerous open source projects I've run into with poor, no, or even wrong documentation.  Therefore, it surprises me that any ecosystem as complex as that of the JHU ACM has as little documentation as it does.  Most of the lore is passed from sysadmin to sysadmin by asking questions as things come up.  Since ACMers never really seem to disappear (and are always in the ACM's IRC channel), this has historically worked, but not worked well.  It has worked in that each sysadmin has acquired the knowledge necessary to fix commonly-broken things and things which break on their watch.  Unfortunately, this means that the knowledge of complex-but-stable systems doesn't get passed down.  And, until this failure, Luna had been a stable system.

A prime example of this issue is the setup of Luna's disks.  I spoke to both of the admins who set up Luna, who swore up and down they had set up RAID1 root disks.  However, I found a machine with only 3 disks in it - Not enough for RAID1 for both the root disk and data.  Further, the disk that was the root disk appeared to have two full system partitions on it, with no real distinction.  I eventually ended up picking the partition with later file mtimes as the real root.  However, because of the lack of documentation, I had to do rather a lot of guesswork here and was very lucky not to have messed anything up irrecoverably.  And I'm not even sure I picked the right root filesystem!

A further issue that prevented me from catching and solving this problem before it became an emergency was credentials.  Though I was officially lab admin as of June, I didn't have all of the keys until two weeks before this failure.

## Failure to Properly Monitor Hardware

The ACM does a decent job of monitoring its systems.  We run [nagios](http://www.nagios.org/) to monitor many of the systems.  For example, Luna has ssh and the RAID array monitored.  In many cases this monitoring would be enough - we've checked that access to the machine is available and that the important data is safe.  This monitoring is actually what started this whole odyssey - I noticed the RAID array was degraded, tried to log in to Luna to check which disk needed replacing and found the root disk had failed out from under me.  So, going forward, I'm going to attempt much more rigorous monitoring of hardware, specifically targeted at always watching the SMART data on all disks.

## Hardware Failure

As I've already mentioned, two (of three) of the disks in Luna failed.  One was a part of a raid array, the other a root disk.  Degraded RAID arrays are fairly common, so I won't go into any detail here about this failure.  I was lucky that the failure mode for the root hard disk was a simple unrecoverable sector, rather than a total hardware failure.  Unrecoverable sectors can be read around with the right software.  Failed hardware requires a duplicate disk and a cleanroom to recover - way beyond my capabilities to procure.

# Failure Mode

Luna's failure mode was one of the more interesting ones I have observed.  The machine and all of its VMs were still running.  I only discovered the failure when I went to log in as root at the local terminal and got an I/O error after entering the username.  Not even a password prompt, just dropped unceremoniously back to the username prompt.  So I asked an older admin to log in using ssh keys.  Oddly enough, this worked.  However, most binaries failed to run.  After some poking around, we figure out that the unrecoverable sector housed some critical binary library to most programs.  And here we got creative.

So what do you do when your system can't run critical binaries?  If you're smart, you take the machine down, hook the drive up to another machine, pull relevant files and build a new operating system.  If you're stupid, crazy or a nerd (or all three), you start making semi-static binaries.

(The following is a rabbit hole, and can safely be skipped)

### Static Binaries

Most modern binaries are incapable of running completely on their own.  That is, they depend on external libraries.  This is done to save space (since you only need to keep one copy of the compiled library on disk) and to simplify upgrades (since you do not need to rebuild every binary which depends on a library if the library changes).  It is possible, though somewhat difficult to build a completely statically compiled system.  In addition, it is probably a bad idea, since several of the core libraries are very large all by themselves.

In a modern dynamically linked system, the majority of the work of finding and loading binaries is done via a library loader.  You can view the library dependencies via a command called `ldd`, which shows you what libraries any particular binary depends on.  Unfortunately, I found out that our copy of lld wouldn't even load.

### Back on track...

Since some binaries would run, it was evident that the broken library wasn't core to everything, just to many, many things on the system (eg: less, cat, login, etc).  After some messing around, I found that python ran.  Great!  If I can get a static version of any binary, I can base64-encode and -decode it to move it over. (Note: see Appendix A for python code and directions to do just this.)

Here I optimized a bit.  I couldn't tell which library was broken, so I couldn't simply copy it over.  At this point I had to consider that the OS was probably a total loss and would need to be rebuilt.  However, I wanted to find out which disks had failed.  In order to minimize downtime (since the machine was mostly running), I decided to do this in-place, on the running, broken OS.  Obviously the smartctl binary on the machine wouldn't run - that would be too easy.  On the recommendation of an older and wiser admin, I took a smartctl binary from a system of a similar vintage and ran it through [statifier](http://statifier.sourceforge.net/), which makes pseduo-static binaries.  A pseudo-static binary is more-or-less the same as a dynamic binary, except that the libraries are also included in the file and therefore do not need to be loaded from disk.  Obviously, this works around the issue of loading a broken library.

## Final Recovery

The final recovery of this machine is mostly not notable.  A friend of mine used a nify sata-usb converter to copy what data he could off the dead root drive.  Because of the bad sector, he ran something like:

```shell
# dd if=/dev/hdX of=file conv=noerror,sync bs=16M
```

This sets dd to go, ignoring errors and copies to the output file "file".  In theory, what we should have gotten was a non-functional system, as there were two blocks it failed to copy.  In practice, once I adjusted the boot record (as we changed from a IDE root disk to a SATA root disk), the system booted right up.  I then added another drive to the RAID array, the system rebuilt it and luna was back to functioning.

# Appendix A - Base 64-encode/-decode migration of a Binary

These are command dumps from the actual luna recovery process.  Please ignore the out-dated nature of the binaries.  This should still all work with modern versions of these programs.

In the following code block, we take a statified binary (smartctl.stat) and base64 encode it.  Note that the output will be very long.  We then copy this to the clipboard.

```shell
$ python
Python 2.4.4 (#2, Oct 22 2008, 19:52:44) 
[GCC 4.1.2 20061115 (prerelease) (Debian 4.1.1-21)] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> import base64, sys
>>> fh=open('smartctl.stat','r')
>>> base64.encode(fh, sys.stdout)
```

Now we set up an environment to write this to disk on the machine that is unable to run binaries.  It base64 decodes the binary on the clipboard and writes it to disk in the current directory.  Feel free to change smartctl to whatever name you think is most appropriate.  Note that where I've marked `[paste]`, the output from the previous is pasted from the clipboard.

```python
import base64, sys
fh=open('smartctl','w')
string="""[paste]"""
fh.write(base64.decodestring(string))
fh.flush()
fh.close()
```
---
title: "Booting Gentoo from LVM in RAID"
date: 2014-09-11 03:56:50
slug: "booting-gentoo-lvm-raid"
categories:
  - "Projects"
---

I run Gentoo Linux on my personal servers, including my RAID server.  (I have a dedicated server for raid and file dumps.  What, you don't?).  When I first set this machine up 2-3 years ago, I gave it a single HDD (yes, spinning iron!) to boot from.  At the time, my rationale was "hey, if it dies, the RAID is intact, I just have to rebuild the system".  Now, I'm changing from having several home directories scattered over all my machines to keeping a unified home directory in AFS.  This means that my RAID is suddenly critical - it goes away and I loose access to my files.  For various reasons, I chose to do this install as a mostly-from-scratch - primarily after three years, spanning the linux 2.6 to 3.x kernel change, quite a lot of useless, outdated or just dead config has built up.

In these instructions, we assume that you wish to set up a bios-booting machine, using GPT partition tables, mdadm software raid, lvm volume management, and grub2\.  We also assume a general familiarity with linux and these technologies.  This install can get quite frustrating if something doesn't work - we'll be using a lot of bleeding-edge pieces of software and documentation (at least, step-by-step-howtos) can be sparse.

# Installation Steps

For the most part, you should be following the [Gentoo Installation Handbook](https://www.gentoo.org/doc/en/handbook/handbook-x86.xml).  The exceptions are sections 4 (preparing the disks), 7 (configuring the kernel) and 10 (configuring the bootloader).  In order to reduce duplication, I'll just write out my versions of these steps.  Finally, after the system is installed and booted, there is some configuration that should be done in order to maximize the reliability of the RAID.

## 4\. Preparing the disks

I'm assuming here you have fresh disks and that the entire disk will be given to the system.  The following steps must be repeated for every drive you plan to use in the array.

We'll be using parted to partition the disks:

```shell
# parted -a optimal /dev/sdX
```

Note that this is set up to automatically shift tings to the optimal alignment when given the choice.

Next, we create a very odd looking partition table.  First, we need to set up a 1MiB+ "grub reserved" partition.  On an EFI system, you could use this as /boot and do [an EFI stub boot](http://wiki.gentoo.org/wiki/UEFI_Gentoo_Quick_Install_Guide), completely skipping the need for a dedicated bootloader.  I want to, but my motherboard's firmware is still a BIOS.  Second, an actual /boot partition.  As far as I am aware, there is no reason this couldn't be done in lvm as well.  However, for my sanity, I didn't try.  And to be honest, I see little utility in putting /boot in lvm anyway - it's usually a very small partition and it's difficult to run out of space in.  Finally, use the rest of the disk to create any swap and lvm partitions you want.  In my case, this looks like:

```shell
(parted) mklabel gpt
(parted) mkpart fat32 grub2 0% 10M
(parted) set 1 bios_grub on
```

(Which creates a 10MiB or so reserved space)

```shell
(parted) mkpart boot ext4 10M 10G
(parted) set 2 lvm on
```

(10 GiB partition for /boot - yes, that's huge.)

```shell
(parted) mkpart swap ext4 10G 11G
```

Swap...

```shell
(parted) mkpart data ext4 11G 100%
(parted) set 4 lvm on
```

This gives a final disklabel that looks like:

```shell
Number  Start   End     Size    File system  Name   Flags
 1      1049kB  10.5MB  9437kB               grub2  bios_grub
 2      10.5MB  10.7GB  10.7GB  ext4         boot   lvm
 3      10.7GB  11.8GB  1074MB               swap
 4      11.8GB  2000GB  1989GB               data   lvm
```

Repeat for each disk, creating the same partition scheme each time (mostly for your sanity).

Next, we need to create the md arrays. md0 is my /boot partition.  I've set it up as a RAID1 - each partition is a straight mirror of every other partition.  In my case, I have 4 disks, so that's 4 copies of the same data.  However, this means that no matter which disk the BIOS picks to boot from, all the data is right there on that disk.I am using md 1.2 metadata (the default at the time of writing).  This is placed some constant length from the start of the partition.  However, it still means that any non-md aware bootloader will be unable to boot from this partition.<sup>[1](#ft1)</sup> 

```shell
# mdadm --create /dev/md0 --name boot  --level=1 /dev/sd{a,b,c,d}2
```

Now, similar for the data partitions:

```shell
# mdadm --create /dev/md2 --name data --level=5 /dev/sd{a,b,c,d}4
```

(The use of /dev/md0 and md2 is a historical thing for me - originally I was planning on striping across my swap partitions.  Then it was pointed out to me that if I lost data on one of them, all of swap would go away.  It is saner to tell linux it has 4 distinct swap partitions)

Next we need to give lvm the data partitions:

```shell
# vgcreate data /dev/md2
```

This creates a volume group with the name data on /dev/md2

Next up is actually creating the logical volume :

```shell
# lvcreate -L SIZE -n root data
```

Which creates a partition of SIZE with the name root on the volume group data.

Now, continue with the gentoo install steps, starting with creating filesystems on /dev/md0 (your /boot) and /dev/mapper/data-root (your root partition)

## 7\. Configuring the Kernel

The simplest way to get your kernel and initramfs configured and booted is though configuring genkernel - it can automatically put all the right options in.  We *could* configure the settings on the command line.  However, I assume you'll want to update your kernel, and it would be best to have consistent settings, right?

Lets start by emerging genkernel onto our system.  While we're at it, since we haven't yet done so inside the chroot, lets emerge mdadm and lvm too.

```shell
# emerge genkernel mdadm lvm2
```

Next, we'll alter genkernel's config by modifying /etc/genkernel.conf.  Make sure the settings are as follows:

```shell
LVM="yes"
MDADM="yes"
DISKLABEL="yes"
REAL_ROOT="/dev/mapper/data-root"
```

Now, go back to using genkernel as documented in the gentoo handbook.

## 10\. Configuring the Bootloader

You really only have one option for bootloader: grub2\.  So follow the gentoo handbook's steps for grub2, with one modification: run

```shell
# grub2-install /dev/sd[DISK]
```

for every disk that is part of your array.  Grub may complain about not being able to find some devices; this message is safe to ignore.  No other configuration should be required.

# Tuning

Now that we're booting there are some things we should do to make sure everything keeps running smoothly.  First off, disabling the write caches on the drives.  This is done because, with the write cache enabled, some drives will report data committed to disk before it actually is.  Where md depends so heavily on the data being in sync, this can cause major data loss.

To disable it, we'll want the hdparm command

```shell
# emerge hdparm
```

Then for each drive:

```shell
# hdparm -W0 /dev/DRIVE
```

which turns off the write cache feature entirely.

While we're at it, there are also some other parameters we should tune.  Primarily these have to do with powersaving and drive spindown.  First, we'll tell the drives to prefer performance over maintaining reduced sound:

```shell
# hdparm -B255 /dev/DRIVE
```

This disables advanced power management.  Linux apparently hasn't had full APM support since the 3.3 series (per [wikipedia](http://en.wikipedia.org/wiki/Advanced_Power_Management)), so we may not actually be changing anything - but it can't hurt.

Next, we're going to disable acoustic management.  This lets drives slow down their spin in order to be quieter.  Personally, my drives are quite quiet, even at full spin - I hear them more when they change speed.

```shell
# hdparm -M254 /dev/DRIVE
```

Finally, I have a WD Green drive in my array (I tend to just buy the cheapest disk when I need one).  These drives are notorious under linux for failing quickly, because their default power management blends poorly with linux's drive access profile.  From the hdparm man page:

> This timeout controls how often the drive parks its heads and enters a low power consumption state.  The factory  default  is  eight  (8)  seconds, which  is a very poor choice for use with Linux.  Leaving it at the default will result in hundreds of thousands of head load/unload cycles in a very short period of time.  The drive mechanism is only rated for 300,000 to 1,000,000 cycles, so leaving it at the default could result in premature failure, not to mention the performance impact of the drive often having to wake-up before doing routine I/O.
> 
> ...
> 
> A  setting  of  30  seconds  is recommended for Linux use.

I set it as long as possible (300 seconds).  I've already proven that power saving is not a priority here.  hdparm considers using this to be dangerous - the mechanism is reverse-engineered, rather than working form any spec.  Therefore, we will need to pass --please-destroy-my-drive to force it to go.

```shell
# hdparm -J 300 --please-destroy-my-drive /dev/sdDRIVE
```

# Monitoring

A RAID array is great and all, but you will need to know when a drive fails.  RAID is meant to mask this to the system, meaning you won't notice it unless you're looking.  But checking your RAID array's health regularly is no fun.  So let's use monitoring.

An option I'm not covering is the use of nagios or another monitoring suite.  They would work well, but are a bit too heavy for this article.

We will be using smartd and mdadm's monitor mode.  Each of them monitors slightly different things.  smartd will warn you if a drive is showing indicators of failure, while mdadm will let you know if a drive has failed.  There will almost certainly be some overlap between the two, but hey, we're building a RAID and redundancy in monitoring can't be bad.

First, lets make sure the relevant software is installed. mdadm is already installed, so let's just take care of smartmontools

```shell
# emerge -uav smartmontools
```

Now, to configure mdadm's monitoring:

```shell
# echo "MAILADDR youremail@your.domain
MAILFROM root@host.name" >> /etc/mdadm.conf
# rc-update add mdadm default
```

What we've just done is told mdadm to monitor the arrays it is aware of, and email whenever there is a change worth noting.  Then, we told the system to start the mdadm monitoring daemon at boot.

Now, on to smart.  We'll set smartd up to scan all devices it can find and email if there is a change.  We use -t to also check both prefailure and usage statistics, in addition to the standard critical health indicators.  Then we have the system start smartd at boot.

```shell
# echo "DEVICESCAN -t -m you@your.domain -M daily" >> /etc/smartd.conf
# rc-update add smartd default
```

Finally, we should routinely scrub RAIDs to verify the data that is present is correct/consistent.  There'd be nothing worse than having all this data stored in RAID, having a single disk failure, and then finding that an entire filesystem is not viable due to a failed block on one of the remaining disks.  This isn't perfect, but it should help in preventing that.  Gentoo has a raid-check package (which is a utility ripped from RHEL), so let's install that:

```shell
# emerge -av raid-check
```

As of the time of writing, raid-check is not stable, so you'll need to deal with that via your preferred method.  (Mine is to use autounmask-write and dispatch-conf).  No further configuration is required.

## Testing monitoring

Monitoring is no good if you don't know you can count on it to notify you properly.  So lets test our monitoring. To test mdadm, run:

```shell
# mdadm --monitor --scan --test -1
```

You should extremely quickly have an email.  If not, check /var/log/messages for useful information, as well as your MTA's log.

Now, smartd.  To test smartd, add -M test to the end of your DEVICESCAN line in /etc/smartd.conf and restart smartd.  It will send mail when it starts.  personally, I've left this test on so that I know this monitoring still functions every time I reboot my server.

# Conclusion

Running a system which boots from lvm on RAID is much easier than it was a couple of years ago - almost all the tools you need for a full solution are in gentoo stable.  That said, it still isn't a simple process and I hope this article has helped you through the process.  Please let me know if you find any errors.

<a id="ft1"></a><sup>1</sup> If you absolutely need to use a different bootloader, I have read about using version 0.9 metadata with a RAID 1\.  v0.9 metadata is stored at the end of the partition and the rest of the partition used as normal - thus allowing it to appear like just a normal filesystem.
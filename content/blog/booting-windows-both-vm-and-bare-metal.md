---
title: "Booting Windows in both a VM and Bare Metal"
date: 2013-01-07 02:51:08
slug: "booting-windows-both-vm-and-bare-metal"
---

So.  My laptop primarily runs linux.  However, I've got a few reasons to run Windows - gaming being one of them, watching streaming SilverLight video (*chough*netflix*cough*) another.  Rebooting a machine every time I want to switch operating systems is rather a drag.  However, for some things (gaming), I'll want to be doing this anyway.  So I figured out how to make Windows both bare-metal boot and VM boot.  I make no guarantees about any sort of performance.

As a side note, I'll probably also play with enabling the Optimus video card on my laptop for the VM.  Letting the video-intensive VM have basically a video card all to itself ought to help performance....

Anyway, on to the setup.

# My Setup/Things you Need

*   VirtualBox
*   Windows 8
*   Windows Install DVD/DVD Image

# Procedure

## Prerequisite: Bare-Metal Dual-Boot

As it says.  I'm assuming here that your machine is already set up and properly dual booting.

## Give Your User Raw Disk Access

Linux really doesn't like users having raw disk access.  However, it is possible.  On my debian system, a simple look at the disks in /dev reveals how:

```shell
$ ls -l /dev/sd*
brw-rw---T 1 root disk 8, 0 Jan  6 22:12 /dev/sda
```

By adding our user to the disk group, they'll be able to have raw disk access.  So lets do that:

```shell
# usermod -aG disk [username]
```

In my case, the simplest way to have this take effect was a reboot.  It certainly didn't take effect while I was still logged in.  If you run into errors later, don't be afraid to reboot.  It may actually solve something.

## Copy Your MBR

We're going to be altering the bootloader on the disk in order to make this work.  The bootloader is the program that bootstraps the operating system up.  Mess up the bootloader and you'll need a rescue disk to get the operating system running again.  The bootloader lives in the first 512 bytes of the hard disk, along with the partition table.  We want both of these.  Here is how to copy them to a file on debian:

```shell
$ dd if=/dev/[diskname] of=[filename].mbr bs=512 count=1
1+0 records in
1+0 records out
512 bytes (512 B) copied, 6.6136e-05 s, 7.7 MB/s
```

## Give VirtualBox Raw Disk Access

For this step, you'll need to know the number of the partition you installed Windows on.  If you don't, this command should help:

```shell
$ VBoxManage internalcommands listpartitions -rawdisk /dev/[diskname]
```

NTFS (which most modern Windows systems use) is partition type 0x07\.  Now, lets create a virtual hard disk which has access to ONLY the windows partition.  We want to give it access to only the windows partition so we cannot accidentally try to boot Linux from in Linux - that would seriously mess up your filesystem.  Without further ado, here is the relevant command:

```shell
$ VBoxManage internalcommands createrawvmdk -filename [Virtual Disk].vmdk -rawdisk /dev/[diskname] -partitions [NTFS Partitions] -mbr [MBR file].mbr
```

Make sure you're using the full disk name - /dev/sda, for example.  See [this page](http://www.virtualbox.org/manual/ch09.html) for more details and documentation.

There will likly be more than one NTFS partition.  List all of them, separated by commas.  (Typically one is the boot partition, while the other contains the full OS)

## Set Up VM

Next, set up the VM.  Tell it to use an existing hard disk - the one we created earlier.

You'll also need to mount your Windows install/repair DVD on the VM for the first startup.

## Boot VM to Install/Repair Disk

On Windows 8 this really only means starting the VM and then pressing a key when asked to.

## 'Repair' the Boot Record

Follow the directions on [this page](http://windows8themes.org/repair-fix-mbr-in-windows-8-using-the-command-prompt.html) to reinstall the Windows bootloader.

## Reboot

Now, reboot the VM.  This time, don't go to the install/repair DVD, let it boot all the way up.  If all has gone well, you will boot straight into Windows.

# Words of Warning

If you adjust your partition table, you'll almost certainly screw everything on your Windows partition up if you don't recopy the MBR.  Windows (bare metal) will think the partition is one size while Windows (VM) will think it is another.  The way to work around this is to recopy the partition table to your MBR file after adjusting the real MBR.  Basically, this entails repeating these steps from "Copy Your MBR" onwards.  Also, skip "Give VirtualBox Raw Disk Access".  This should copy the new partition table, then re-install the Windows bootloader. 

If that doesn't work, just remove the VM and all of its disks and start this over from the beginning.
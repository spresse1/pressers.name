---
title: "Lenovo 300e Gen 2, Part 4: Laptop/slate Driver Investigation"
date: 2023-01-05T18:00:00+02:00
---

# Recap

In [Part 3]({{< relref lenovo-300e-pt3-acpi-investigation >}}), we dug through the ACPI definition of the Laptop/slate indicator. While we don't understand absolutely everything about how it works, we're confident that the ACPI definitions look relatively normal.

This time, let's start looking at driver integrations.

# Identifiers Recap

We got the following [identifiers out of Windows in part 1]({{< relref "lenovo-300e-gen2-linux#collecting-identifiers" >}}):

* BIOS Name: `\_SB.CIND`
* Compatible IDs: `ACPI\PNP0C60` and `PNP0C60`
* Hardware IDs: `ACPI\VEN_AMDI&DEV_0081`, `ACPI\AMDI0081`, `*AMDI0081`
* Device Instance Path: `ACPI\AMDI0081\0`

In part 3, we saw that:

* `PNP0C60` is a [Microsoft identifier](https://uefi.org/PNP_ID_List?search=PNP)
* `AMDI0081` is an [AMD identifier](https://uefi.org/ACPI_ID_List?search=AMDI)

So let's dig into these identifiers and see if we can turn up anything useful online.

# Searching... Searching...

## `AMDI0081`

No meaningful results. But result 4 points to this series of posts, so... yay?

## `PNP0C60`

Lots of results!

The most useful ones are from Microsoft:

* This page has a [basic description of a laptop/slate mode indicator](https://learn.microsoft.com/en-us/windows-hardware/drivers/gpiobtn/button-implementation) using the correct ID for this device. It implies this is most likely some kind of GPIO device (or there's a secondary driver under Windows that we missed doing event injection).
* [This one mentions the requirements for such a device](https://learn.microsoft.com/en-us/windows-hardware/drivers/bringup/other-acpi-namespace-objects#convertible-pc-sensing-device). However, it implies there should be a `_CRS` method, which there isn't. At least while we're running linux.
* Here is a [sample ACPI description](https://learn.microsoft.com/en-us/windows-hardware/drivers/gpiobtn/acpi-descriptor-samples#acpi-description-for-laptopslate-mode-indicator) for this device type from Microsoft. No `_CRS` method, but not tons of methods on that page in any case.
* And finally, a [general description of how Microsoft thinks of tablets, docking, and convertibles](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/continuum)

Outside of Microsoft, there are a few resources that mention this identifier. Oddly enough, one that does is [this potential patch](https://patchwork.kernel.org/project/linux-acpi/patch/1472628817-3145-1-git-send-email-wnhuang@google.com/) to the Linux kernel. Ultimately it didn't go in and it's not super clear what it's trying to do.

What's concerning about that patch is that it seems to expect a method to be present that we can call. We've... just got `_STA`, and that shouldn't work on its own.

There are two possibilities:

* `_STA` is being used in a non-standard way
* There's another device and/or driver under windows that we missed.

Either of these would require a separate windows driver. So back to Windows. I repeated the experiment of disabling devices until the laptop/slate sensor stopped working.

Annnd.. it turns out there's another one: the "AMD Sensor Fusion Hub".

![Device Manager screenshot, showing the "BIOS device name" property of the "AMD Sensor Fusion Hub". The value is "\_SB.PCI0.GP17.MP2C"](/static/images/300e/SensorHubBIOSDevName.PNG)

![Device Manager screenshot, showing the "Hardware ids" property of the "AMD Sensor Fusion Hub". The values are "PCI\VEN_1022&DEV_15E4&SUBSYS_380517AA&REV_00", "PCI\VEN_1022&DEV_15E4&SUBSYS_380517AA", "PCI\VEN_1022&DEV_15E4&CC_000000", and "PCI\VEN_1022&DEV_15E4&CC_0000"](/static/images/300e/SensorHubHWIDs.PNG)

We get the following identifiers for this device:

* `\_SB.PCI0.GP17.MP2C`
* `PCI\VEN_1022&DEV_15E4&SUBSYS_380517AA&REV_00`
* `PCI\VEN_1022&DEV_15E4&SUBSYS_380517AA`
* `PCI\VEN_1022&DEV_15E4&CC_000000`
* `PCI\VEN_1022&DEV_15E4&CC_0000`

This appears to be a PCI device. I wonder what `lspci` says about it? We've got PCI identifiers, so let's query for the specific device:

```shell
[steve@fedora acpidump]$ sudo lspci -vk -d 1022:15e4
[sudo] password for steve: 
03:00.7 Non-VGA unclassified device: Advanced Micro Devices, Inc. [AMD] Sensor Fusion Hub
        Subsystem: Lenovo Device 3805
        Flags: bus master, fast devsel, latency 0, IRQ 32, IOMMU group 11
        Memory at fc400000 (32-bit, non-prefetchable) [size=1M]
        Memory at fc6cc000 (32-bit, non-prefetchable) [size=8K]
        Capabilities: [48] Vendor Specific Information: Len=08 <?>
        Capabilities: [50] Power Management version 3
        Capabilities: [64] Express Endpoint, MSI 00
        Capabilities: [a0] MSI: Enable- Count=1/2 Maskable- 64bit+
        Capabilities: [c0] MSI-X: Enable- Count=2 Masked-
        Capabilities: [100] Vendor Specific Information: ID=0001 Rev=1 Len=010 <?>
        Kernel driver in use: pcie_mp2_amd
        Kernel modules: amd_sfh

[steve@fedora acpidump]$ 
```

Lots, but only a few elements are useful. First, the first line confirms this is an "AMD Sensor Fusion Hub", whatever that means. Perhaps we can search for it later. We see a bunch of data on how it interacts with PCI that isn't relevant -- at least yet. And finally, we see information on two kernel drivers: `pcie_mp2_amd` and `amd_sfh`.

These kernel modules have documentation ([amd_sfh](https://docs.kernel.org/hid/amd-sfh-hid.html) and [i2c-amd-mp2](https://www.kernel.org/doc/html/latest/i2c/busses/i2c-amd-mp2.html)), but it's not much that's terribly useful for us - there simply isn't much that's useful for us doing debugging.

So let's look at some source:

* i2c-amd-mp2:
   * [i2c-amd-mp2.h](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/i2c/busses/i2c-amd-mp2.h?h=v6.0.9) - A header file, lots of definitions and stuff we may need later.
   * [i2c-amd-mp2-pci.c](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/i2c/busses/i2c-amd-mp2-pci.c?h=v6.0.9) - Not much to see here. I think this is just bus setup and data handling stuff.
   * [i2c-amd-mp2-plat.c](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/i2c/busses/i2c-amd-mp2-plat.c?h=v6.0.9) - Again, not much to see.
* amd_sfh:
   * [amd_sfh_hid.c](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_hid.c) implements the kernel HID (Human Interface Device) interface for sensors. Not useful yet, but maybe later?
   * [amd_sfh_pcie.c](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_pcie.c) - Lots of stuff about detecting machines, has a sensor mask setting which we might need to use later if it's not detecting the sensor correctly or something similar.
   * [amd_sfh_client.c](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_client.c) - Jackpot! [Line 294](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_client.c#n294) will give us the list of detected sensors and their status.

So since there are drivers, let's see what they put in `dmesg` - maybe there's something going wrong there?

# Driver `dmesg`

Checking `dmesg` for `amd_sfh` or `pcie_mp2_amd`:

```shell
[steve@fedora ~]$ sudo dmesg | grep -e pcie_mp2_amd -e amd_sfh
[sudo] password for steve: 
[    6.746418] pcie_mp2_amd 0000:03:00.7: enabling device (0000 -> 0002)
[steve@fedora ~]$
```

That's not much. After some research, there doesn't seem to be a default way to enable debug in the driver. The source we saw has a fair number of debug messages using the `dev_dbg` function, but [this requires recompiling the kernel to use](https://stackoverflow.com/questions/50504516/enable-linux-kernel-driver-dev-dbg-debug-messages). That said, it doesn't look like we have any choice, so let's build us a kernel!

# Building a kernel

A word of forewarning: Building a kernel on this machine does not make sense. It's not meant to be a workhorse machine -- and with only two cores/four threads and 4GiB of DDR4 ram, it's never going to be.

I also found that with a split drive (between Windows and Linux), I didn't have enough space on the disk to build the kernel, even when I did try.

I ended up building the kernel on my primary Debian machine, so the next section will have some small asides about how to do that.

Additionally, I chose to build a vanilla Linux kernel, rather than a Fedora one. For me, this is just a matter of familiarity - I've built lots of Linux kernels, but never done it with the Fedora patches. Another reason to use the vanilla kernel -- albeit, a minor one -- is that if fixing this requires a kernel patch, we'll know whatever we develop will work on the generic kernel.

Finally, it is worth noting that fedora has an excellent page on [building the kernel](https://docs.fedoraproject.org/en-US/quick-docs/kernel/build-custom-kernel/), which we'll use a bit of.

From this point on, anything with a simple `$` prompt indicates it is being run on my Debian machine, while anything with a full prompt (`[steve@fedora ~]$`) is being run on the 300e.

## Installing packages

First up, we'll [install the packages necessary to build the kernel](https://wiki.debian.org/BuildADebianKernelPackage):

```shell
$ sudo apt-get install build-essential linux-source bc kmod cpio flex libncurses5-dev libelf-dev libssl-dev dwarves bison 
```

Besides building the kernel, we'll want to package it to make it easier to put on the system. There are good targets in the linux kernel for doing that -- we'll get to them later. Fedora needs rpms, so we'll have to figure out how to build rpms on Debian.

Turns out getting an environment is pretty trivial:

```shell
$ sudo apt-get install rpm
```

And with that, let's move on to getting kernel sources.

## Getting kernel sources

We can download a tarball from [kernel.org](https://www.kernel.org/). I used 6.0.7 because that was the latest stable release when I did this.

```shell
$ wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.0.7.tar.xz
```

Then we'll untar the resulting download:

```shell
$ tar xf linux-6.0.7
```

And done, source acquired!

## Get kernel configuration

You'll need to copy the kernel config from the 300e. It should be found at `/boot/config-*`. Place it in the kernel source directory and name it `.config`. In my case, I copied it via SSH:

```shell
$ cd linux-6.0.7
$ scp steve@fedora:/boot/config-* .config
```

The kernel regularly adds new config options, so the first thing we should do is bring this configuration up to date. The following command will do so, taking the default option for every choice.

```shell
$ make olddefconfig
```

## Kernel signing

Many modern machines require either booting signed kernels or explicitly turning off kernel signing. This (generally speaking) is to cut down on rootkits. In general, a significant positive, but something we have to deal with here. Pick one of the below methods to handle this. Setting up kernel signing is probably better long-term as we keep the safety protection, but enabling unsigned kernels is easier.

If you want to go the unsigned kernel route, [skip to enabling unsigned kernels]({{< relref "#enable-unsigned-kernels" >}}). Otherwise, keep reading.

### Configuring signing kernels

Kernel signing generates a kernel signed with a key -- in this case, an autogenerated one. The system firmware can then later verify that the kernel was signed with this key and hasn't been tampered with, which it considers to be enough security. However, we also have to notify the hardware of the key, so that it can verify against it. If you're curious about the details of this, reading about SecureBoot will get you many, many more details.

The key can be automatically generated by the kernel at build time (if it doesn't already exist). Then after the build, we'll add the key to the machine.

The kernel documentation on [signing kernel modules](https://www.kernel.org/doc/html/v6.0/admin-guide/module-signing.html) is very useful, although it doesn't cover adding the key to the system. 

First, check that the key generation settings file is present:

```shell
$ ls certs/x509.genkey 
certs/x509.genkey
$
```

If you don't have `certs/x509.genkey`, copy `certs/default_x509.genkey` to `certs/x509.genkey`:

```shell
$ cp certs/default_x509.genkey certs/x509.genkey
$
```

The first thing we have to do is configure this key as a shim signing key, which can be done by applying this patch.

```patch
--- certs/x509.genkey   2022-11-03 16:00:35.000000000 +0100
+++ certs/x509.genkey   2022-12-11 21:59:58.367669814 +0100
@@ -15,3 +15,4 @@
 keyUsage=digitalSignature
 subjectKeyIdentifier=hash
 authorityKeyIdentifier=keyid
```

At this stage, check `certs/x509.genkey` for anything you want to change:

```shell
$ cat certs/x509.genkey
[ req ]
default_bits = 4096
distinguished_name = req_distinguished_name
prompt = no
string_mask = utf8only
x509_extensions = myexts

[ req_distinguished_name ]
#O = Unspecified company
CN = Build time autogenerated kernel key
#emailAddress = unspecified.user@unspecified.company

[ myexts ]
basicConstraints=critical,CA:FALSE
keyUsage=digitalSignature
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid
```

Personally, I changed `CN` and `emailAddress`. These values are pretty much just for your records, so set them to whatever will be meaningful for you. `CN` in particular will show up in the name of this key when listing keys known to system firmware, so it should be something useful.

Next, we have to configure the build to actually sign the kernel for us as part of installation.

```patch
--- arch/x86/Makefile   2022-12-11 12:50:13.646535340 +0100
+++ arch/x86/Makefile   2022-12-12 13:21:13.323626839 +0100
@@ -271,6 +271,9 @@
 endif
        $(Q)$(MAKE) $(build)=$(boot) $(KBUILD_IMAGE)
        $(Q)mkdir -p $(objtree)/arch/$(UTS_MACHINE)/boot
+ifneq ($(CONFIG_MODULE_SIG_KEY),)
+       $(Q)sbsign --key $(CONFIG_MODULE_SIG_KEY) --cert $(CONFIG_MODULE_SIG_KEY) --output $(KBUILD_IMAGE) $(KBUILD_IMAGE)
+endif
        $(Q)ln -fsn ../../x86/boot/bzImage $(objtree)/arch/$(UTS_MACHINE)/boot/$@
 
 $(BOOT_TARGETS): vmlinux
```

This patch signs the kernel so long as a signing key is available. It integrates it with the `bzImage` Makefile rule for x86 systems. This should mean that any x86 kernel that gets built also gets signed. So even if we build or package the kernel differently later, it should still get signed.

As a note, I had to install `sbsign`, which is part of the `sbsigntool` package on Debian.

If you've done a build in this kernel before, you already have signing keys, and we'll need to remove them to regenerate them with new values:

```shell
$ rm -f certs/signing_key.{pem,x509}
$
```

And with that we should be prepared for the build, from a signing perspective. After the build, we'll add the generated keys to the machine key store.

Now, [skip to turning on driver debugging]({{< relref "#turning-on-driver-debugging" >}}) 

### Enable Unsigned Kernels

Unfortunately (for us), this system is set up so that it won't boot unsigned kernels. We can turn this protection off in the BIOS or we can register our own key. Turning it off is easier while we're debugging - but if we have to run a patched kernel long-term it'll be better to simply add our own key.

Anyway, here are the basic steps:

1. Turn off the machine.
2. Power it up and repeatedly press [Fn+F2 (or just F2 or F12 or..)](https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/300-series/300e-windows-2nd-gen/solutions/ht500216-recommended-way-to-enter-bios-ideapad) until the machine goes into the BIOS.
3. Navigate (using the mouse or keyboard) to "security", then "secure boot".
4. Change the setting to "Disabled" (apologies for the photo of a screen - it's the best I could do while in the BIOS)
   ![Lenovo 300e BIOS screen showing that secure boot is disabled. Unfortunately, I don't believe there is an accessible way to do this. I would be happy to record all the keystrokes necessary to go through this process, but it will be inaccessible and without a mechanism for getting feedback.](/static/images/300e/DisableSecureBoot.jpg)
5. Press Fn+F10 to save and exit. Unfortunately, this will pop up an error, which you can safely ignore. Secure boot is disabled, despite the error.

## Turning on driver debugging

Okay! We've got the kernel source, we've installed the tools to configure it, and we've got a configuration! Just one thing remains before we do the build: turning on the debug options.

The linux kernel documentation is generally excellent, and includes a [guide to kernel debug messages](https://www.kernel.org/doc/html/v6.0/admin-guide/dynamic-debug-howto.html). Per this guide, if we want to see `dev_dbg()` messages, we need to set two flags in the module at compile time: `-DDEBUG` and `-DDYNAMIC_DEBUG_MODULE`. You can either manually add them to `drivers/hid/amd-sfh-hid/Makefile` or use the patch below:

```patch
--- drivers/hid/amd-sfh-hid/Makefile
+++ drivers/hid/amd-sfh-hid/Makefile
@@ -14,4 +14,4 @@
 amd_sfh-objs += sfh1_1/amd_sfh_interface.o
 amd_sfh-objs += sfh1_1/amd_sfh_desc.o
 
-ccflags-y += -I $(srctree)/$(src)/
+ccflags-y += -I $(srctree)/$(src)/ -DDEBUG -DDYNAMIC_DEBUG_MODULE
```

And with that, we're ready to build!

## Build Kernel

The following command should build the kernel, package it (and the headers) into a nice RPM and place them in `~/rpmbuild/RPMS/x86_64/`.

```shell
$ make -j $(( $( cat /proc/cpuinfo | grep processor | wc -l ) - 2 )) binrpm-pkg
```

Note that the argument to `-j` controls the number of threads the kernel can use while building. This is set to use two less than the number of processors on your machine, so that you can keep using it while it builds. Feel free to adjust that to your needs.

## Install

### Kernel

Okay, now that the kernel has built, we need to copy it over to the 300e and install it.

Copy:

```shell
$ scp ~/rpmbuild/RPMS/x86_64/kernel*.rpm steve@fedora:
```

And move back to the 300e and we'll install the kernel

```shell
[steve@fedora ~]$ sudo rpm -i kernel-6.0.7-1.x86_64.rpm
[steve@fedora ~]$ sudo grub2-mkconfig -o /boot/grub/grub.conf
```

### Signing keys

If you opted to use a signing key above, we have some further work to do. First, we need to extract *just* the public key from the certificate. On the build machine:

```shell
$ openssl x509 -in certs/signing_key.pem -out certs/signing_key.der -outform DER
```

Next, we'll copy this public key to the 300e. From the machine where you performed the build:

```shell
$ scp certs/signing_key.der steve@fedora:
steve@10.0.3.110's password:
$
```

Finally, back on the 300e, we'll enroll this as a MOK (Machine Owner Key). This prompts for a password -- this password is used later to ensure you do intend to use this key as a MOK. When you next reboot you'll be prompted for it, then never again.

```shell
[steve@fedora ~]$ sudo mokutil --import signing_key.der 
[sudo] password for steve: 
input password: 
input password again: 
[steve@fedora ~]$ 
```

Your next step is to reboot, but we'll do that as part of our wrap-up. Remember, you'll be prompted for the MOK password!

#### Optionally, save Signing Keys

There is an optional step having to do with key management. If you want to keep using this key for future kernel builds, we'll want to save it somewhere. Re-using this key means not having to enroll a key again in the future. To keep using this key, copy the .pem somewhere on your build machine (I used ~/.kernel-key.pem):

```shell
$ cp certs/signing_key.pem ~/.kernel-key.pem
```

Then change `CONFIG_MODULE_SIG_KEY` in `.config` to point to the path of the key:

```patch
--- .config 2022-12-11 18:24:07.232354935 +0100
+++ .config 2022-12-11 18:24:39.368512040 +0100
@@ -9864,7 +9864,7 @@
 #
 # Certificates for signature checking
 #
-CONFIG_MODULE_SIG_KEY="certs/signing_key.pem"
+CONFIG_MODULE_SIG_KEY="~/.kernel-key.pem"
 CONFIG_MODULE_SIG_KEY_TYPE_RSA=y
 # CONFIG_MODULE_SIG_KEY_TYPE_ECDSA is not set
 CONFIG_SYSTEM_TRUSTED_KEYRING=y
```

Alternatively, you can set this by running `make menuconfig`, then selecting "Cryptographic API", then "Certificates for signature checking".

If you carry forward the `.config`, this will just keep working. Otherwise, you'll have to set it again for every new `.config`

### Install wrap-up

And that's it! Now that the kernel is installed, let's reboot the machine and see if we get any more results.

```shell
[steve@fedora ~]$ sudo reboot
```

# Now with debugging!

## Enable debugging

The first thing we have to do is turn on debugging output:

```shell
[steve@fedora ~]$ echo "file drivers/hid/amd-sfh-hid/* +p" | sudo tee /sys/kernel/debug/dynamic_debug/control
file drivers/hid/amd-sfh-hid/* +p
[steve@fedora ~]$
```

We can check that this worked by seeing that the kernel module is in `/sys/kernel/debug/dynamic_debug/control`:

```shell
[steve@fedora ~]$ sudo cat /sys/kernel/debug/dynamic_debug/control | grep amd-sfh
drivers/hid/amd-sfh-hid/amd_sfh_client.c:361 [amd_sfh]amd_sfh_hid_client_deinit =p "stopping sid 0x%x (%s) status 0x%x\012"
drivers/hid/amd-sfh-hid/amd_sfh_client.c:197 [amd_sfh]amd_sfh_suspend =p "suspend sid 0x%x (%s) status 0x%x\012"
drivers/hid/amd-sfh-hid/amd_sfh_client.c:174 [amd_sfh]amd_sfh_resume =p "resume sid 0x%x (%s) status 0x%x\012"
drivers/hid/amd-sfh-hid/sfh1_1/amd_sfh_init.c:309 [amd_sfh]amd_sfh1_1_init =p "firmware version 0x%x\012"
drivers/hid/amd-sfh-hid/sfh1_1/amd_sfh_init.c:249 [amd_sfh]amd_sfh_suspend =p "suspend sid 0x%x (%s) status 0x%x\012"
drivers/hid/amd-sfh-hid/sfh1_1/amd_sfh_init.c:224 [amd_sfh]amd_sfh_resume =p "resume sid 0x%x (%s) status 0x%x\012"
amd_sfh_hid_client_deinit =p "stopping sid 0x%x (%s) status 0x%x\012"
```

(Output may vary somewhat, but if you get any results, debug is on and working)

## Remove the module and reload it

Okay, so now we can remove the kernel module, reload it, and assume we'll see whatever debugging output is available.

```shell
[steve@fedora ~]$ sudo rmmod amd_sfh
[steve@fedora ~]$ sudo modprobe amd_sfh
[steve@fedora ~]$
```

## Anything in syslog?

So what do we get in syslog?

```shell
[steve@fedora ~]$ sudo dmesg | grep -e pcie_mp2_amd -e amd_sfh
[ 1539.377611] pcie_mp2_amd 0000:03:00.7: sid 0x0 (accelerometer) status 0x5
[steve@fedora ~]$ 
```

Alright! We found an accelerometer! But we have to break that message down to know more than that.

That message looks like it comes from [amd_sfh_client.c:294](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_client.c#n294) or [amd_sfh_client.c:301](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_client.c#n301) - unfortunately both print the exact same message!

The code for those messages is (with reformatting):

```c
dev_dbg(dev, "sid 0x%x (%s) status 0x%x\n",
        cl_data->sensor_idx[i],
        get_sensor_name(cl_data->sensor_idx[i]),
        cl_data->sensor_sts[i]);
```

Off the bat, we know what the first two arguments are:

* `dev` is the device that the driver is currently working with
* The string is a format string for the message to be printed.
   * We can also guess that the `sid` is a "sensor index" - something for keeping track of which sensor is which. This is given in the third argument.
   * The `%s` is a string. In the fourth argument, we can see that this string comes from a call to `get_sensor_name()`, so this is probably the name of a sensor type (aka: accelerometer).
   * And finally, the status is.. well, probably a status, given in the fifth argument.

So what does the message we got in `dmesg` mean? The index and type are pretty straightforward. This is sensor 0, which is an accelerometer. Status however, is not simple - what does `0x5` mean?

Looking [one line up at line 293](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/hid/amd-sfh-hid/amd_sfh_client.c#n293), we can see the value `SENSOR_DISABLED` (conditionally) assigned to `cl_data->sensor_sts[i]`, which is then the status as printed. Let's see if chasing `SENSOR_DISABLED` helps us understand what `0x5` indicates.

First, let's see if `SENSOR_DISABLED` is defined in this driver:

```shell
linux-6.0.7$ cd drivers/hid/amd-sfh-hid/
linux-6.0.7/drivers/hid/amd-sfh-hid$ grep -riIn SENSOR_DISABLED | grep define
amd_sfh_common.h:23:#define SENSOR_DISABLED                     5
```

Huh. That was easy. Looks like 0x5 indicates that the sensor is disabled. But that's all the feedback we got and we don't even know what line the message comes from! We definitely need to learn how to debug kernel drivers...

But that's for the next time!

# Coming up...

Next time we'll make use of our ability to install and run our own kernels to debug this kernel driver and learn exactly what it's doing.
---
title: "Lenovo 300e Gen 2, Part 2: lshw, lspci, dmesg, and some initial investigation"
date: 2022-11-16T13:00:00+02:00
---

# Recap

[Last time we determined what devices don't work under Linux]({{< relref lenovo-300e-gen2-linux >}}) - the touchpad and the laptop/tablet mode sensor. We also went in and gathered some useful hardware identifiers for these devices.

Next, we'll reboot to Linux and do some early exploratory work.

# A Word on Distros

For various reasons, I ended up installing [Fedora Workstation 37](https://getfedora.org/). I'm going to use it as the "working" linux distro while I explore and fix -- and from there, potentially try others.

Why Fedora? Normally on new hardware, I try something that keeps the newest software possible. In the past, I've used [Manjaro Linux](https://manjaro.org/download/), as it strikes an excellent balance between "easy to boot/install" and "up-to-date". For whatever reason, I couldn't get it to boot - the system refused to recognize the USB drive.

On my "stable" systems, I tend to run [Debian Linux](https://www.debian.org/download). As someone who often works with bleeding edge systems, it's nice when I don't have to come home and play systems administrator -- at least not too often. Debian is great for stability, but it can lag behind on harddware support. So it wasn't a good choice.

I honestly haven't run Fedora in years, if ever. But they have a relatively up to date prerelease with an up-to-date gnome with improved touchscreen support -- important for this system with a touchscreen. So let's give it a shot and once everything works we can re-evaluate.

Additionally, I ended up setting up the machine to dual boot with Windows -- just in case I need it for anything later.

Anyway, with a linux distro picked (at least for now) and installed, let's get started...

# Reboot to Linux!

Armed with these identifiers, let's reboot to Linux and see what we can find.

I tend to start with simple things, just to see what all is there. So let's try `lshw`, `lspci -k`, and `dmesg` first and see what we find.

Install lshw:
```shell
[steve@fedora ~]$ sudo dnf install lshw
Fedora 37 - x86_64                               23 kB/s |  15 kB     00:00    
Fedora 37 - x86_64                              613 kB/s | 1.7 MB     00:02    
Fedora Modular 37 - x86_64                       26 kB/s |  16 kB     00:00    
Fedora Modular 37 - x86_64                      343 kB/s | 179 kB     00:00    
Fedora 37 - x86_64 - Updates                     35 kB/s |  19 kB     00:00    
Fedora Modular 37 - x86_64 - Updates            100 kB/s |  19 kB     00:00    
Fedora 37 - x86_64 - Test Updates                18 kB/s |  16 kB     00:00    
Fedora 37 - x86_64 - Test Updates               399 kB/s | 525 kB     00:01    
Fedora Modular 37 - x86_64 - Test Updates        23 kB/s |  17 kB     00:00    
Dependencies resolved.
================================================================================
 Package       Architecture    Version                    Repository       Size
================================================================================
Installing:
 lshw          x86_64          B.02.19.2-8.fc37           fedora          307 k

Transaction Summary
================================================================================
Install  1 Package

Total download size: 307 k
Installed size: 793 k
Is this ok [y/N]: y
Downloading Packages:
lshw-B.02.19.2-8.fc37.x86_64.rpm                1.6 MB/s | 307 kB     00:00    
--------------------------------------------------------------------------------
Total                                           723 kB/s | 307 kB     00:00     
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                        1/1 
  Installing       : lshw-B.02.19.2-8.fc37.x86_64                           1/1 
  Running scriptlet: lshw-B.02.19.2-8.fc37.x86_64                           1/1 
  Verifying        : lshw-B.02.19.2-8.fc37.x86_64                           1/1 

Installed:
  lshw-B.02.19.2-8.fc37.x86_64                                                  

Complete!
[steve@fedora ~]$
```

I believe `lspci` is already installed. If not, `sudo dnf install pciutils` will install `lspci`. `dmesg` is _definitely_ installed by default.

Why run `lspci -k`? This shows the kernel module associated with each device. If a device doesn't have a kernel module associated, we may want to give it some extra scrutiny.

The full output of these commands is at the bottom of the post. It's long!

What do we learn from looking through these? Well, not much. There's a bunch of AMD Raven/Raven2 functions that don't have a driver associated: 

```shell
[steve@fedora ~]$ lspci -k
[snip]
00:18.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 0
00:18.1 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 1
00:18.2 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 2
00:18.3 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 3
	Kernel driver in use: k10temp
	Kernel modules: k10temp
00:18.4 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 4
00:18.5 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 5
00:18.6 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 6
00:18.7 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 7
[snip]
```

But it's too early for me to say if these are related to anything we care about at this point.

The devices we're looking for are an ACPI device and an i2c device, so let's see if anything turns up in `dmesg` for them. I've cut out many not-yet-relevant messages from below:

```shell
[steve@fedora ~]$ sudo dmesg | grep ACPI
[snip]
[    0.252377] ACPI: Added _OSI(Module Device)
[    0.252381] ACPI: Added _OSI(Processor Device)
[    0.252383] ACPI: Added _OSI(3.0 _SCP Extensions)
[    0.252385] ACPI: Added _OSI(Processor Aggregator Device)
[    0.252388] ACPI: Added _OSI(Linux-Dell-Video)
[    0.252390] ACPI: Added _OSI(Linux-Lenovo-NV-HDMI-Audio)
[    0.252393] ACPI: Added _OSI(Linux-HPI-Hybrid-Graphics)
[    0.267939] ACPI: 10 ACPI AML tables successfully acquired and loaded
[    0.270637] ACPI: [Firmware Bug]: BIOS _OSI(Linux) query ignored
[    0.273384] ACPI: EC: EC started
[    0.273386] ACPI: EC: interrupt blocked
[    0.273520] ACPI: EC: EC_CMD/EC_SC=0x666, EC_DATA=0x662
[    0.273523] ACPI: \_SB_.PCI0.LPC0.H_EC: Boot DSDT EC used to handle transactions
[    0.273526] ACPI: Interpreter enabled
[    0.273546] ACPI: PM: (supports S0 S3 S4 S5)
[    0.273548] ACPI: Using IOAPIC for interrupt routing
[    0.273701] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
[    0.274039] ACPI: Enabled 4 GPEs in block 00 to 1F
[    0.284177] ACPI: PCI Root Bridge [PCI0] (domain 0000 [bus 00-ff])
[snip]
[    0.313601] pnp: PnP ACPI init
[    0.316266] pnp: PnP ACPI: found 5 devices
[    0.908885] ACPI: AC: AC Adapter [ADP1] (off-line)
[    0.908970] ACPI: button: Power Button [PWRB]
[    0.909037] ACPI: button: Lid Switch [LID0]
[    0.909147] ACPI: button: Power Button [PWRF]
[snip]
```

There are a couple interesting messages in there. First:

```shell
[    0.270637] ACPI: [Firmware Bug]: BIOS _OSI(Linux) query ignored
[snip]
[    0.273701] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
```

This indicates an avenue of investigation. ACPI allows the operating system to identify itself to the BIOS and for the BIOS to alter behavior based on this identification. This is handy if a BIOS developer wants to offload work from the BIOS (eg: to a driver) under one OS but not another. However, some BIOSes use it to check that the OS is one they know how to interact with and ignore all others.

So this is one avenue to investigate -- the BIOS may not be configured to be at all compatible with non-Windows OSes. Maybe we have to tell Linux to identify itself to ACPI as Windows. So once we're done looking through this, we'll try adding those kernel flags and see what happens.

Second:

```shell
[    0.313601] pnp: PnP ACPI init
[    0.316266] pnp: PnP ACPI: found 5 devices
[    0.908885] ACPI: AC: AC Adapter [ADP1] (off-line)
[    0.908970] ACPI: button: Power Button [PWRB]
[    0.909037] ACPI: button: Lid Switch [LID0]
[    0.909147] ACPI: button: Power Button [PWRF]
```

This indicates that ACPI plug-and-play is in use and that it found several buttons - including the laptop lid switch (which detects when the screen of the laptop is flat against the keyboard - in other words, when the screen is closed).

Okay, what about i2c?

```shell
[steve@fedora ~]$ sudo dmesg | grep -i i2c
[    2.543148] input: ELAN238E:00 04F3:2894 Touchscreen as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input5
[    2.543350] input: ELAN238E:00 04F3:2894 as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input6
[    2.543436] input: ELAN238E:00 04F3:2894 as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input7
[    2.543534] input: ELAN238E:00 04F3:2894 Stylus as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input8
[    2.543743] hid-generic 0018:04F3:2894.0001: input,hidraw0: I2C HID v1.00 Device [ELAN238E:00 04F3:2894] on i2c-ELAN238E:00
[    2.597395] input: ELAN238E:00 04F3:2894 as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input11
[    2.597588] input: ELAN238E:00 04F3:2894 UNKNOWN as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input12
[    2.597685] input: ELAN238E:00 04F3:2894 UNKNOWN as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input13
[    2.597811] input: ELAN238E:00 04F3:2894 Stylus as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input14
[    2.598438] hid-multitouch 0018:04F3:2894.0001: input,hidraw0: I2C HID v1.00 Device [ELAN238E:00 04F3:2894] on i2c-ELAN238E:00
[steve@fedora ~]$ 
```

We definitely found _an_ i2c device. But that last line - including `hiddraw` - indicates this is most likely the touch screen, not the touch pad. Further confirming this is the fact that there's a stylus associated with this device:

```
[    2.543534] input: ELAN238E:00 04F3:2894 Stylus as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input8
```

Finally, the ID associated is `ELAN238E`. The touchpad identifiers included `SYNA2392`.

So no magically recognized but otherwise not working devices. Drat. That means we'll have to start altering things and see what happens.

# Altering reported ACPI OS

Earlier we saw that the BIOS may be one that misbehaves if the OS doesn't report itself as Windows. So let's try reporting as Windows. This might help the tablet/slate switch, if it's disabling itself because it only is designed to work under Windows. And, quite honestly, it's the only lead we got from the general examination, without having to dive into really deep specifics.

The kernel is, in my opinion, some of the best documented software out there, although the documentation can sometimes be a little scattered. A quick search for "kernel command line parameters" brings us [the kernel documentation on command line parameters](https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html). Somewhat down the page is the complete list of options, more-or-less starting with a ton of ACPI options.

## Adding `pci=nocrs`

First let's try adding the flag that this message mentions:

```shell
[    0.273701] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
```

Since we don't want to permanently add `pci=nocrs` to the kernel command line arguments (yet), we'll [temporarily set it as a kernel boot parameter](https://linuxconfig.org/how-to-set-kernel-boot-parameters-on-linux). (In short, boot to grub, press `e` to edit the boot script, find the line that begins in `linux`, add `pci=nocrs` to the end, and press `ctrl+x` or `F10` to boot).

So I did all that and booted and...

It didn't fix anything. In fact, it made it worse -- now the WiFi adapter isn't found. I guess that isn't the solution. Good thing we only added the boot parameter temporarily, right?  We can reboot, not modify the grub configuration, and have a clean environment.

## Pretending to be Windows 10

This machine comes with Windows 10 by default. Perhaps some of the things aren't working because the BIOS won't show them to anything but Windows?

Looking through the [Linux kernel command line parameters](), two mention identifying the OS to the BIOS: `acpi_os_name` and `acpi_osi`.

The help for `acpi_os_name` says:

```
acpi_os_name=   [HW,ACPI] Tell ACPI BIOS the name of the OS
                Format: To spoof as Windows 98: ="Microsoft Windows"
```

That's pretty straightforward, but it doesn't tell us how to spoof Windows 10. Let's come back to it.

The help for `acpi_osi` is long. Mostly it's describing how to specify multiple OSes. So here's what matters:

```
acpi_osi=       [HW,ACPI] Modify list of supported OS interface strings
```

What's the difference? I believe `acpi_os_name` is intended to specify the actual running OS, while `acpi_osi` specifies that the OS is or is compatible with the named OS. A smart developer would check `acpi_osi`, because Windows 11 wil support the Windows 10 interface. Just checking `acpi_os_name` means needing to release a new BIOS whenever there's a new version of Windows!

So, let's start by specifying `acpi_opi`. We want to say we're Windows 10, but still don't know how. So... to your favorite search engine!

That brings us to [this table of ACPI OSI IDs for various windows versions](https://learn.microsoft.com/en-us/windows-hardware/drivers/acpi/winacpi-osi#_osi-strings-for-windows-operating-systems)! Unfortunately, we don't know what version of Windows 10 this may be looking for. So we'll try them all...

Specifically, we're going to add the following kernel arguments:

`acpi_osi="Windows 2015" acpi_osi="Windows 2016" acpi_osi="Windows 2017" acpi_osi="Windows 2017.2" acpi_osi="Windows 2018" acpi_osi="Windows 2018.2" acpi_osi="Windows 2019" acpi_osi="Windows 2020" acpi_osi="Windows 2021" acpi_osi="Windows 2022"`

That's an awful lot, but if it works we can trim it down later.

So how'd it work?

No change. The tablet/slate sensor doesn't work and the touchpad doesn't work. So this isn't the solution.

## Last ditch effort

So let's take one last longshot before we really start digging in: setting `acpi_os_name` to "Windows 2020":

`acpi_os_name="Windows 2020"`

And did that work?

Of course not!

# What's next?

So this strategy was a total bust. Personally, I don't find that surprising. I was working off a single, possibly-unrelated error in `dmesg` output, which probably means I was jumping to conclusions and trying something without thinking it through or investigating first. However, it was worth the effort to eliminate one possible reason devices might not be working. Honestly, you could just as easily skip everything we tried here (except the `lshw`, `lspci`, and `dmesg` data gathering!) and move on to the next step. However, this is a thing I tried, and so I'm including it here. Although it failed for this, it might work for something else and therefore is important to include in the record.

So what's next? In [part 3]({{< relref lenovo-300e-pt3-acpi-investigation >}}) we'll start digging through the ACPI details of ACPI for the tablet/slate indicator.

# Long outputs

## `lshw` output

```shell
[steve@fedora ~]$ sudo lshw
[sudo] password for steve: 
fedora                      
    description: Convertible
    product: 82GK (LENOVO_MT_82GK_BU_idea_FM_300e 2nd Gen)
    vendor: LENOVO
    version: Lenovo 300e 2nd Gen
    serial: REMOVED
    width: 64 bits
    capabilities: smbios-3.2.0 dmi-3.2.0 smp vsyscall32
    configuration: administrator_password=disabled boot=normal chassis=convertible family=300e 2nd Gen frontpanel_password=disabled keyboard_password=disabled power-on_password=disabled sku=LENOVO_MT_82GK_BU_idea_FM_300e 2nd Gen uuid=REMOVED
  *-core
       description: Motherboard
       product: LNVNB161216
       vendor: LENOVO
       physical id: 0
       version: SDK0K13476WIN
       serial: REMOVED
       slot: Base Board Chassis Location
     *-memory
          description: System Memory
          physical id: 1
          slot: System board or motherboard
          size: 4GiB
        *-bank
             description: Row of chips DDR4 Synchronous Unbuffered (Unregistered) 3200 MHz (0.3 ns)
             product: M471A5244CB0-CWE
             vendor: Samsung
             physical id: 0
             serial: 00000000
             slot: DIMM 0
             size: 4GiB
             width: 64 bits
             clock: 3200MHz (0.3ns)
     *-cache:0
          description: L1 cache
          physical id: 3
          slot: L1 - Cache
          size: 192KiB
          capacity: 192KiB
          clock: 1GHz (1.0ns)
          capabilities: pipeline-burst internal write-back unified
          configuration: level=1
     *-cache:1
          description: L2 cache
          physical id: 4
          slot: L2 - Cache
          size: 1MiB
          capacity: 1MiB
          clock: 1GHz (1.0ns)
          capabilities: pipeline-burst internal write-back unified
          configuration: level=2
     *-cache:2
          description: L3 cache
          physical id: 5
          slot: L3 - Cache
          size: 4MiB
          capacity: 4MiB
          clock: 1GHz (1.0ns)
          capabilities: pipeline-burst internal write-back unified
          configuration: level=3
     *-cpu
          description: CPU
          product: AMD 3015e with Radeon Graphics
          vendor: Advanced Micro Devices [AMD]
          physical id: 6
          bus info: cpu@0
          version: AMD 3015e with Radeon Graphics
          serial: Null
          slot: FT5
          size: 957MHz
          capacity: 2400MHz
          width: 64 bits
          clock: 100MHz
          capabilities: lm fpu fpu_exception wp vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp x86-64 constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb hw_pstate ssbd ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 rdseed adx smap clflushopt sha_ni xsaveopt xsavec xgetbv1 xsaves clzero irperf xsaveerptr arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif overflow_recov succor smca sev sev_es cpufreq
          configuration: cores=2 enabledcores=2 threads=4
     *-firmware
          description: BIOS
          vendor: LENOVO
          physical id: a
          version: FRCN23WW
          date: 06/01/2022
          size: 128KiB
          capacity: 16MiB
          capabilities: acpi usb biosbootspecification netboot uefi
     *-pci:0
          description: Host bridge
          product: Raven/Raven2 Root Complex
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 100
          bus info: pci@0000:00:00.0
          version: 00
          width: 32 bits
          clock: 33MHz
        *-generic UNCLAIMED
             description: IOMMU
             product: Raven/Raven2 IOMMU
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 0.2
             bus info: pci@0000:00:00.2
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: msi ht bus_master cap_list
             configuration: latency=0
        *-pci:0
             description: PCI bridge
             product: Raven/Raven2 PCIe GPP Bridge [6:0]
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 1.2
             bus info: pci@0000:00:01.2
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: pci pm pciexpress msi ht normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:26 memory:fc000000-fc1fffff
           *-network
                description: Wireless interface
                product: QCA6174 802.11ac Wireless Network Adapter
                vendor: Qualcomm Atheros
                physical id: 0
                bus info: pci@0000:01:00.0
                logical name: wlp1s0
                version: 32
                serial: 74:4c:a1:ff:ff:ff
                width: 64 bits
                clock: 33MHz
                capabilities: pm msi pciexpress bus_master cap_list ethernet physical wireless
                configuration: broadcast=yes driver=ath10k_pci driverversion=5.19.7 firmware=WLAN.RM.4.4.1-00288- ip=REMOVED latency=0 link=yes multicast=yes wireless=IEEE 802.11
                resources: irq:49 memory:fc000000-fc1fffff
        *-pci:1
             description: PCI bridge
             product: Raven/Raven2 PCIe GPP Bridge [6:0]
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 1.6
             bus info: pci@0000:00:01.6
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: pci pm pciexpress msi ht normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:27 memory:fc700000-fc7fffff
           *-generic
                description: MMC Host
                product: SD/MMC Card Reader Controller
                vendor: O2 Micro, Inc.
                physical id: 0
                bus info: pci@0000:02:00.0
                logical name: mmc1
                version: 01
                width: 32 bits
                clock: 33MHz
                capabilities: pm msi pciexpress bus_master cap_list
                configuration: driver=sdhci-pci latency=0
                resources: irq:42 memory:fc701000-fc701fff memory:fc700000-fc7007ff
        *-pci:2
             description: PCI bridge
             product: Raven/Raven2 Internal PCIe GPP Bridge 0 to Bus A
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 8.1
             bus info: pci@0000:00:08.1
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: pci pm pciexpress msi normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:28 ioport:1000(size=4096) memory:fc300000-fc6fffff ioport:130000000(size=1094411354112)
           *-display
                description: VGA compatible controller
                product: Picasso/Raven 2 [Radeon Vega Series / Radeon Vega Mobile Series]
                vendor: Advanced Micro Devices, Inc. [AMD/ATI]
                physical id: 0
                bus info: pci@0000:03:00.0
                logical name: /dev/fb0
                version: e9
                width: 64 bits
                clock: 33MHz
                capabilities: pm pciexpress msi msix vga_controller bus_master cap_list fb
                configuration: depth=32 driver=amdgpu latency=0 mode=1366x768 visual=truecolor xres=1366 yres=768
                resources: iomemory:10-f iomemory:10-f irq:43 memory:130000000-13fffffff memory:140000000-1401fffff ioport:1000(size=256) memory:fc600000-fc67ffff
           *-multimedia:0
                description: Audio device
                product: Raven/Raven2/Fenghuang HDMI/DP Audio Controller
                vendor: Advanced Micro Devices, Inc. [AMD/ATI]
                physical id: 0.1
                bus info: pci@0000:03:00.1
                version: 00
                width: 32 bits
                clock: 33MHz
                capabilities: pm pciexpress msi bus_master cap_list
                configuration: driver=snd_hda_intel latency=0
                resources: irq:46 memory:fc6c8000-fc6cbfff
           *-generic:0
                description: Encryption controller
                product: Family 17h (Models 10h-1fh) Platform Security Processor
                vendor: Advanced Micro Devices, Inc. [AMD]
                physical id: 0.2
                bus info: pci@0000:03:00.2
                version: 00
                width: 32 bits
                clock: 33MHz
                capabilities: pm pciexpress msi msix bus_master cap_list
                configuration: driver=ccp latency=0
                resources: irq:30 memory:fc500000-fc5fffff memory:fc6ce000-fc6cffff
           *-usb
                description: USB controller
                product: Raven2 USB 3.1
                vendor: Advanced Micro Devices, Inc. [AMD]
                physical id: 0.3
                bus info: pci@0000:03:00.3
                version: 00
                width: 64 bits
                clock: 33MHz
                capabilities: pm pciexpress msi msix xhci bus_master cap_list
                configuration: driver=xhci_hcd latency=0
                resources: irq:32 memory:fc300000-fc3fffff
              *-usbhost:0
                   product: xHCI Host Controller
                   vendor: Linux 5.19.7 xhci-hcd
                   physical id: 0
                   bus info: usb@1
                   logical name: usb1
                   version: 6.00
                   capabilities: usb-2.00
                   configuration: driver=hub slots=6 speed=480Mbit/s
                 *-usb:0
                      description: Bluetooth wireless interface
                      product: QCA61x4 Bluetooth 4.0
                      vendor: Qualcomm Atheros Communications
                      physical id: 5
                      bus info: usb@1:5
                      version: 0.01
                      capabilities: bluetooth usb-2.01
                      configuration: driver=btusb maxpower=100mA speed=12Mbit/s
                 *-usb:1
                      description: Video
                      product: EasyCamera
                      vendor: Chicony Electronics Co.,Ltd.
                      physical id: 6
                      bus info: usb@1:6
                      version: 10.69
                      serial: 0001
                      capabilities: usb-2.01
                      configuration: driver=uvcvideo maxpower=500mA speed=480Mbit/s
              *-usbhost:1
                   product: xHCI Host Controller
                   vendor: Linux 5.19.7 xhci-hcd
                   physical id: 1
                   bus info: usb@2
                   logical name: usb2
                   version: 6.00
                   capabilities: usb-3.10
                   configuration: driver=hub slots=4 speed=10000Mbit/s
           *-multimedia:1
                description: Multimedia controller
                product: ACP/ACP3X/ACP6x Audio Coprocessor
                vendor: Advanced Micro Devices, Inc. [AMD]
                physical id: 0.5
                bus info: pci@0000:03:00.5
                version: 00
                width: 32 bits
                clock: 33MHz
                capabilities: pm pciexpress msi bus_master cap_list
                configuration: driver=snd_pci_acp3x latency=0
                resources: irq:45 memory:fc680000-fc6bffff
           *-multimedia:2
                description: Audio device
                product: Family 17h/19h HD Audio Controller
                vendor: Advanced Micro Devices, Inc. [AMD]
                physical id: 0.6
                bus info: pci@0000:03:00.6
                version: 00
                width: 32 bits
                clock: 33MHz
                capabilities: pm pciexpress msi bus_master cap_list
                configuration: driver=snd_hda_intel latency=0
                resources: irq:47 memory:fc6c0000-fc6c7fff
           *-generic:1
                description: Non-VGA unclassified device
                product: Sensor Fusion Hub
                vendor: Advanced Micro Devices, Inc. [AMD]
                physical id: 0.7
                bus info: pci@0000:03:00.7
                version: 00
                width: 32 bits
                clock: 33MHz
                capabilities: pm pciexpress msi msix bus_master cap_list
                configuration: driver=pcie_mp2_amd latency=0
                resources: irq:32 memory:fc400000-fc4fffff memory:fc6cc000-fc6cdfff
        *-pci:3
             description: PCI bridge
             product: Raven/Raven2 Internal PCIe GPP Bridge 0 to Bus B
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 8.2
             bus info: pci@0000:00:08.2
             version: 00
             width: 32 bits
             clock: 33MHz
             capabilities: pci pm pciexpress msi normal_decode bus_master cap_list
             configuration: driver=pcieport
             resources: irq:29 memory:fc200000-fc2fffff
           *-sata
                description: SATA controller
                product: FCH SATA Controller [AHCI mode]
                vendor: Advanced Micro Devices, Inc. [AMD]
                physical id: 0
                bus info: pci@0000:04:00.0
                version: 61
                width: 32 bits
                clock: 33MHz
                capabilities: sata pm pciexpress msi ahci_1.0 bus_master cap_list
                configuration: driver=ahci latency=0
                resources: irq:31 memory:fc200000-fc2007ff
        *-serial
             description: SMBus
             product: FCH SMBus Controller
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 14
             bus info: pci@0000:00:14.0
             version: 61
             width: 32 bits
             clock: 66MHz
             configuration: driver=piix4_smbus latency=0
             resources: irq:0
        *-isa
             description: ISA bridge
             product: FCH LPC Bridge
             vendor: Advanced Micro Devices, Inc. [AMD]
             physical id: 14.3
             bus info: pci@0000:00:14.3
             version: 51
             width: 32 bits
             clock: 66MHz
             capabilities: isa bus_master
             configuration: latency=0
     *-pci:1
          description: Host bridge
          product: Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 101
          bus info: pci@0000:00:01.0
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:2
          description: Host bridge
          product: Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 102
          bus info: pci@0000:00:08.0
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:3
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 0
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 103
          bus info: pci@0000:00:18.0
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:4
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 1
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 104
          bus info: pci@0000:00:18.1
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:5
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 2
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 105
          bus info: pci@0000:00:18.2
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:6
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 3
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 106
          bus info: pci@0000:00:18.3
          version: 00
          width: 32 bits
          clock: 33MHz
          configuration: driver=k10temp
          resources: irq:0
     *-pci:7
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 4
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 107
          bus info: pci@0000:00:18.4
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:8
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 5
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 108
          bus info: pci@0000:00:18.5
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:9
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 6
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 109
          bus info: pci@0000:00:18.6
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pci:10
          description: Host bridge
          product: Raven/Raven2 Device 24: Function 7
          vendor: Advanced Micro Devices, Inc. [AMD]
          physical id: 10a
          bus info: pci@0000:00:18.7
          version: 00
          width: 32 bits
          clock: 33MHz
     *-pnp00:00
          product: PnP device PNP0c02
          physical id: 0
          capabilities: pnp
          configuration: driver=system
     *-pnp00:01
          product: PnP device PNP0b00
          physical id: 2
          capabilities: pnp
          configuration: driver=rtc_cmos
     *-pnp00:02
          product: PnP device PTL0001
          vendor: Pantel Inc
          physical id: 7
          capabilities: pnp
          configuration: driver=i8042 kbd
     *-pnp00:03
          product: PnP device PNP0c02
          physical id: 8
          capabilities: pnp
          configuration: driver=system
     *-pnp00:04
          product: PnP device PNP0c01
          physical id: 9
          capabilities: pnp
          configuration: driver=system
  *-mmc0
       description: MMC Host
       physical id: 1
       logical name: mmc0
     *-device
          description: SD/MMC Device
          product: MMC64G
          vendor: Unknown (245)
          physical id: 1
          bus info: mmc@0:0001
          date: 12/2020
          serial: 164002
          capabilities: mmc
        *-interface:0
             physical id: 1
             logical name: /dev/mmcblk0rpmb
        *-interface:1
             physical id: 2
             logical name: /dev/mmcblk0
             size: 62537072640
             capabilities: gpt-1.00 partitioned partitioned:gpt
             configuration: guid=ee428c7b-52d9-4889-a22c-addc8267165b logicalsectorsize=512 sectorsize=512
           *-volume:0 UNCLAIMED
                description: Windows FAT volume
                vendor: MSDOS5.0
                physical id: 1
                version: FAT32
                serial: 5c1d-4bea
                size: 255MiB
                capacity: 259MiB
                capabilities: boot nomount fat initialized
                configuration: FATs=2 filesystem=fat label=SYSTEM_DRV name=EFI System Partition
           *-volume:1
                description: reserved partition
                vendor: Windows
                physical id: 2
                logical name: /dev/mmcblk0p2
                serial: 74c6ba0c-639e-4f16-bea4-8e5a40a48d75
                capacity: 15MiB
                capabilities: nofs nomount
                configuration: name=Microsoft reserved partition
           *-volume:2
                description: Windows NTFS volume
                vendor: Windows
                physical id: 3
                logical name: /dev/mmcblk0p3
                version: 3.1
                serial: e075f9e9-ebbb-9144-8843-a2dab987b028
                size: 32GiB
                capacity: 32GiB
                capabilities: ntfs initialized
                configuration: clustersize=4096 created=2021-07-08 07:12:19 filesystem=ntfs label=Windows name=Basic data partition state=clean
           *-volume:3
                description: Windows NTFS volume
                vendor: Windows
                physical id: 4
                logical name: /dev/mmcblk0p4
                version: 3.1
                serial: 10ec5775-1fbd-a84a-ba3e-9f0a30894861
                size: 984MiB
                capacity: 999MiB
                capabilities: boot precious nomount ntfs initialized
                configuration: clustersize=4096 created=2021-07-08 07:12:21 filesystem=ntfs label=WINRE_DRV name=Basic data partition state=clean
           *-volume:4
                description: EXT4 volume
                vendor: Linux
                physical id: 5
                logical name: /dev/mmcblk0p5
                logical name: /boot
                version: 1.0
                serial: 09ebd8dc-d007-47c9-bee5-c4e5742a3e66
                size: 1GiB
                capabilities: journaled extended_attributes large_files huge_files dir_nlink recover 64bit extents ext4 ext2 initialized
                configuration: created=2022-11-04 12:56:39 filesystem=ext4 lastmountpoint=/boot modified=2022-11-07 15:31:46 mount.fstype=ext4 mount.options=rw,seclabel,relatime mounted=2022-11-07 15:31:46 state=mounted
           *-volume:5
                description: EXT4 volume
                vendor: Linux
                physical id: 6
                logical name: /dev/mmcblk0p6
                logical name: /
                version: 1.0
                serial: 401c1fb3-860c-469e-b303-427cc66e377c
                size: 23GiB
                capabilities: journaled extended_attributes large_files huge_files dir_nlink recover 64bit extents ext4 ext2 initialized
                configuration: created=2022-11-04 12:56:43 filesystem=ext4 lastmountpoint=/ modified=2022-11-07 10:31:40 mount.fstype=ext4 mount.options=rw,seclabel,relatime mounted=2022-11-07 15:31:42 state=mounted
```

## `lspci` output:
```shell
[steve@fedora ~]$ lspci -k
00:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Root Complex
	Subsystem: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Root Complex
00:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 IOMMU
	Subsystem: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 IOMMU
00:01.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge
00:01.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 PCIe GPP Bridge [6:0]
	Subsystem: Advanced Micro Devices, Inc. [AMD] Device 1234
	Kernel driver in use: pcieport
00:01.6 PCI bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 PCIe GPP Bridge [6:0]
	Subsystem: Advanced Micro Devices, Inc. [AMD] Device 1234
	Kernel driver in use: pcieport
00:08.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 00h-1fh) PCIe Dummy Host Bridge
00:08.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Internal PCIe GPP Bridge 0 to Bus A
	Subsystem: Advanced Micro Devices, Inc. [AMD] Device 0000
	Kernel driver in use: pcieport
00:08.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Internal PCIe GPP Bridge 0 to Bus B
	Subsystem: Advanced Micro Devices, Inc. [AMD] Device 0000
	Kernel driver in use: pcieport
00:14.0 SMBus: Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller (rev 61)
	Subsystem: Lenovo Device 383a
	Kernel driver in use: piix4_smbus
	Kernel modules: i2c_piix4, sp5100_tco
00:14.3 ISA bridge: Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge (rev 51)
	Subsystem: Lenovo Device 3839
00:18.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 0
00:18.1 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 1
00:18.2 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 2
00:18.3 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 3
	Kernel driver in use: k10temp
	Kernel modules: k10temp
00:18.4 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 4
00:18.5 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 5
00:18.6 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 6
00:18.7 Host bridge: Advanced Micro Devices, Inc. [AMD] Raven/Raven2 Device 24: Function 7
01:00.0 Network controller: Qualcomm Atheros QCA6174 802.11ac Wireless Network Adapter (rev 32)
	Subsystem: Lenovo Device 0827
	Kernel driver in use: ath10k_pci
	Kernel modules: ath10k_pci
02:00.0 SD Host controller: O2 Micro, Inc. SD/MMC Card Reader Controller (rev 01)
	Subsystem: Lenovo Device 3829
	Kernel driver in use: sdhci-pci
	Kernel modules: sdhci_pci
03:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Picasso/Raven 2 [Radeon Vega Series / Radeon Vega Mobile Series] (rev e9)
	Subsystem: Lenovo Device 380c
	Kernel driver in use: amdgpu
	Kernel modules: amdgpu
03:00.1 Audio device: Advanced Micro Devices, Inc. [AMD/ATI] Raven/Raven2/Fenghuang HDMI/DP Audio Controller
	Subsystem: Lenovo Device 3809
	Kernel driver in use: snd_hda_intel
	Kernel modules: snd_hda_intel
03:00.2 Encryption controller: Advanced Micro Devices, Inc. [AMD] Family 17h (Models 10h-1fh) Platform Security Processor
	Subsystem: Lenovo Device 3821
	Kernel driver in use: ccp
	Kernel modules: ccp
03:00.3 USB controller: Advanced Micro Devices, Inc. [AMD] Raven2 USB 3.1
	Subsystem: Lenovo Device 3807
	Kernel driver in use: xhci_hcd
03:00.5 Multimedia controller: Advanced Micro Devices, Inc. [AMD] ACP/ACP3X/ACP6x Audio Coprocessor
	Subsystem: Lenovo Device 3804
	Kernel driver in use: snd_pci_acp3x
	Kernel modules: snd_pci_acp3x, snd_rn_pci_acp3x, snd_pci_acp5x, snd_pci_acp6x, snd_sof_amd_renoir
03:00.6 Audio device: Advanced Micro Devices, Inc. [AMD] Family 17h/19h HD Audio Controller
	Subsystem: Lenovo Device 3803
	Kernel driver in use: snd_hda_intel
	Kernel modules: snd_hda_intel
03:00.7 Non-VGA unclassified device: Advanced Micro Devices, Inc. [AMD] Sensor Fusion Hub
	Subsystem: Lenovo Device 3805
	Kernel driver in use: pcie_mp2_amd
	Kernel modules: amd_sfh
04:00.0 SATA controller: Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode] (rev 61)
	Subsystem: Advanced Micro Devices, Inc. [AMD] FCH SATA Controller [AHCI mode]
	Kernel driver in use: ahci
```

## `dmesg` output:
```shell
[steve@fedora ~]$ sudo dmesg
[sudo] password for steve: 
[    0.000000] Linux version 5.19.7-300.fc37.x86_64 (mockbuild@bkernel01.iad2.fedoraproject.org) (gcc (GCC) 12.2.1 20220819 (Red Hat 12.2.1-1), GNU ld version 2.38-23.fc37) #1 SMP PREEMPT_DYNAMIC Mon Sep 5 15:09:01 UTC 2022
[    0.000000] Command line: BOOT_IMAGE=(hd0,gpt5)/vmlinuz-5.19.7-300.fc37.x86_64 root=UUID=401c1fb3-860c-469e-b303-427cc66e377d ro rhgb quiet
[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'
[    0.000000] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256
[    0.000000] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'compacted' format.
[    0.000000] signal: max sigframe size: 1776
[    0.000000] BIOS-provided physical RAM map:
[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009efff] usable
[    0.000000] BIOS-e820: [mem 0x000000000009f000-0x000000000009ffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000000e0000-0x00000000000fffff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000000100000-0x0000000009bfffff] usable
[    0.000000] BIOS-e820: [mem 0x0000000009c00000-0x0000000009d80fff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000009d81000-0x0000000009efffff] usable
[    0.000000] BIOS-e820: [mem 0x0000000009f00000-0x0000000009f0afff] ACPI NVS
[    0.000000] BIOS-e820: [mem 0x0000000009f0b000-0x00000000c8aeffff] usable
[    0.000000] BIOS-e820: [mem 0x00000000c8af0000-0x00000000cc57dfff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000cc57e000-0x00000000ce57dfff] ACPI NVS
[    0.000000] BIOS-e820: [mem 0x00000000ce57e000-0x00000000ce5fdfff] ACPI data
[    0.000000] BIOS-e820: [mem 0x00000000ce5fe000-0x00000000cf7fffff] usable
[    0.000000] BIOS-e820: [mem 0x00000000cf800000-0x00000000cfffffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000f8000000-0x00000000fbffffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000fd200000-0x00000000fd2fffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000fed80000-0x00000000fed80fff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000100000000-0x000000010effffff] usable
[    0.000000] BIOS-e820: [mem 0x000000010f000000-0x000000012effffff] reserved
[    0.000000] BIOS-e820: [mem 0x000000012f340000-0x000000012fffffff] reserved
[    0.000000] NX (Execute Disable) protection: active
[    0.000000] e820: update [mem 0xad492018-0xad49f457] usable ==> usable
[    0.000000] e820: update [mem 0xad492018-0xad49f457] usable ==> usable
[    0.000000] extended physical RAM map:
[    0.000000] reserve setup_data: [mem 0x0000000000000000-0x000000000009efff] usable
[    0.000000] reserve setup_data: [mem 0x000000000009f000-0x000000000009ffff] reserved
[    0.000000] reserve setup_data: [mem 0x00000000000e0000-0x00000000000fffff] reserved
[    0.000000] reserve setup_data: [mem 0x0000000000100000-0x0000000009bfffff] usable
[    0.000000] reserve setup_data: [mem 0x0000000009c00000-0x0000000009d80fff] reserved
[    0.000000] reserve setup_data: [mem 0x0000000009d81000-0x0000000009efffff] usable
[    0.000000] reserve setup_data: [mem 0x0000000009f00000-0x0000000009f0afff] ACPI NVS
[    0.000000] reserve setup_data: [mem 0x0000000009f0b000-0x00000000ad492017] usable
[    0.000000] reserve setup_data: [mem 0x00000000ad492018-0x00000000ad49f457] usable
[    0.000000] reserve setup_data: [mem 0x00000000ad49f458-0x00000000c8aeffff] usable
[    0.000000] reserve setup_data: [mem 0x00000000c8af0000-0x00000000cc57dfff] reserved
[    0.000000] reserve setup_data: [mem 0x00000000cc57e000-0x00000000ce57dfff] ACPI NVS
[    0.000000] reserve setup_data: [mem 0x00000000ce57e000-0x00000000ce5fdfff] ACPI data
[    0.000000] reserve setup_data: [mem 0x00000000ce5fe000-0x00000000cf7fffff] usable
[    0.000000] reserve setup_data: [mem 0x00000000cf800000-0x00000000cfffffff] reserved
[    0.000000] reserve setup_data: [mem 0x00000000f8000000-0x00000000fbffffff] reserved
[    0.000000] reserve setup_data: [mem 0x00000000fd200000-0x00000000fd2fffff] reserved
[    0.000000] reserve setup_data: [mem 0x00000000fed80000-0x00000000fed80fff] reserved
[    0.000000] reserve setup_data: [mem 0x0000000100000000-0x000000010effffff] usable
[    0.000000] reserve setup_data: [mem 0x000000010f000000-0x000000012effffff] reserved
[    0.000000] reserve setup_data: [mem 0x000000012f340000-0x000000012fffffff] reserved
[    0.000000] efi: EFI v2.70 by Phoenix Technologies Ltd.
[    0.000000] efi: ACPI=0xce5fd000 ACPI 2.0=0xce5fd014 TPMFinalLog=0xce42e000 SMBIOS=0xca45d000 SMBIOS 3.0=0xca450000 MEMATTR=0xc563b018 ESRT=0xc91b6000 MOKvar=0xc91bd000 TPMEventLog=0xad4a0018 
[    0.000000] secureboot: Secure boot disabled
[    0.000000] SMBIOS 3.2.0 present.
[    0.000000] DMI: LENOVO 82GK/LNVNB161216, BIOS FRCN23WW 06/01/2022
[    0.000000] tsc: Fast TSC calibration using PIT
[    0.000000] tsc: Detected 1197.745 MHz processor
[    0.000022] e820: update [mem 0x00000000-0x00000fff] usable ==> reserved
[    0.000027] e820: remove [mem 0x000a0000-0x000fffff] usable
[    0.000040] last_pfn = 0x10f000 max_arch_pfn = 0x400000000
[    0.000581] x86/PAT: Configuration [0-7]: WB  WC  UC- UC  WB  WP  UC- WT  
[    0.000806] last_pfn = 0xcf800 max_arch_pfn = 0x400000000
[    0.007592] esrt: Reserving ESRT space from 0x00000000c91b6000 to 0x00000000c91b60d8.
[    0.007611] Using GB pages for direct mapping
[    0.008302] secureboot: Secure boot disabled
[    0.008304] RAMDISK: [mem 0xad4a8000-0xb0380fff]
[    0.008310] ACPI: Early table checksum verification disabled
[    0.008316] ACPI: RSDP 0x00000000CE5FD014 000024 (v02 LENOVO)
[    0.008323] ACPI: XSDT 0x00000000CE5FB188 0000EC (v01 LENOVO CB-01    00000003 PTEC 00000002)
[    0.008334] ACPI: FACP 0x00000000C91E3000 00010C (v05 LENOVO CB-01    00000003 PTEC 00000002)
[    0.008343] ACPI: DSDT 0x00000000C91D4000 009154 (v01 LENOVO AMD      00001000 INTL 20180313)
[    0.008348] ACPI: FACS 0x00000000CDB7E000 000040
[    0.008353] ACPI: SSDT 0x00000000CA488000 000681 (v01 LENOVO UsbCUcsi 00000001 INTL 20180313)
[    0.008358] ACPI: SSDT 0x00000000CA482000 005419 (v02 LENOVO AmdTable 00000002 MSFT 02000002)
[    0.008363] ACPI: SSDT 0x00000000CA430000 000632 (v02 LENOVO Tpm2Tabl 00001000 INTL 20180313)
[    0.008368] ACPI: TPM2 0x00000000CA42F000 000034 (v03 LENOVO CB-01    00000002 PTEC 00000002)
[    0.008373] ACPI: MSDM 0x00000000CA40A000 000055 (v03 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008378] ACPI: BATB 0x00000000CA3E6000 00004A (v02 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008382] ACPI: HPET 0x00000000C91E2000 000038 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008387] ACPI: APIC 0x00000000C91E1000 000108 (v03 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008392] ACPI: MCFG 0x00000000C91E0000 00003C (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008397] ACPI: SBST 0x00000000C91DF000 000030 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008402] ACPI: WSMT 0x00000000C91DE000 000028 (v01 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008406] ACPI: VFCT 0x00000000C91C6000 00D484 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008411] ACPI: IVRS 0x00000000C91C5000 00013E (v02 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008416] ACPI: SSDT 0x00000000C91C4000 0008E0 (v01 LENOVO AMD CPU  00000001 AMD  00000001)
[    0.008421] ACPI: CRAT 0x00000000C91C3000 000490 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008425] ACPI: CDIT 0x00000000C91C2000 000029 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008430] ACPI: FPDT 0x00000000C91C0000 000034 (v01 LENOVO CB-01    00000002 PTEC 00000002)
[    0.008435] ACPI: SSDT 0x00000000C91B9000 0013AE (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008440] ACPI: SSDT 0x00000000C91B7000 001556 (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008445] ACPI: SSDT 0x00000000C91B3000 002745 (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008449] ACPI: BGRT 0x00000000C91B2000 000038 (v01 LENOVO CB-01    00000002 PTEC 00000002)
[    0.008454] ACPI: UEFI 0x00000000CDB7D000 000116 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008459] ACPI: SSDT 0x00000000C91BF000 00045F (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008464] ACPI: SSDT 0x00000000C91BE000 000743 (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008468] ACPI: Reserving FACP table memory at [mem 0xc91e3000-0xc91e310b]
[    0.008470] ACPI: Reserving DSDT table memory at [mem 0xc91d4000-0xc91dd153]
[    0.008472] ACPI: Reserving FACS table memory at [mem 0xcdb7e000-0xcdb7e03f]
[    0.008473] ACPI: Reserving SSDT table memory at [mem 0xca488000-0xca488680]
[    0.008475] ACPI: Reserving SSDT table memory at [mem 0xca482000-0xca487418]
[    0.008477] ACPI: Reserving SSDT table memory at [mem 0xca430000-0xca430631]
[    0.008478] ACPI: Reserving TPM2 table memory at [mem 0xca42f000-0xca42f033]
[    0.008480] ACPI: Reserving MSDM table memory at [mem 0xca40a000-0xca40a054]
[    0.008481] ACPI: Reserving BATB table memory at [mem 0xca3e6000-0xca3e6049]
[    0.008483] ACPI: Reserving HPET table memory at [mem 0xc91e2000-0xc91e2037]
[    0.008484] ACPI: Reserving APIC table memory at [mem 0xc91e1000-0xc91e1107]
[    0.008486] ACPI: Reserving MCFG table memory at [mem 0xc91e0000-0xc91e003b]
[    0.008487] ACPI: Reserving SBST table memory at [mem 0xc91df000-0xc91df02f]
[    0.008489] ACPI: Reserving WSMT table memory at [mem 0xc91de000-0xc91de027]
[    0.008490] ACPI: Reserving VFCT table memory at [mem 0xc91c6000-0xc91d3483]
[    0.008492] ACPI: Reserving IVRS table memory at [mem 0xc91c5000-0xc91c513d]
[    0.008494] ACPI: Reserving SSDT table memory at [mem 0xc91c4000-0xc91c48df]
[    0.008495] ACPI: Reserving CRAT table memory at [mem 0xc91c3000-0xc91c348f]
[    0.008497] ACPI: Reserving CDIT table memory at [mem 0xc91c2000-0xc91c2028]
[    0.008498] ACPI: Reserving FPDT table memory at [mem 0xc91c0000-0xc91c0033]
[    0.008500] ACPI: Reserving SSDT table memory at [mem 0xc91b9000-0xc91ba3ad]
[    0.008501] ACPI: Reserving SSDT table memory at [mem 0xc91b7000-0xc91b8555]
[    0.008503] ACPI: Reserving SSDT table memory at [mem 0xc91b3000-0xc91b5744]
[    0.008504] ACPI: Reserving BGRT table memory at [mem 0xc91b2000-0xc91b2037]
[    0.008506] ACPI: Reserving UEFI table memory at [mem 0xcdb7d000-0xcdb7d115]
[    0.008508] ACPI: Reserving SSDT table memory at [mem 0xc91bf000-0xc91bf45e]
[    0.008509] ACPI: Reserving SSDT table memory at [mem 0xc91be000-0xc91be742]
[    0.008619] No NUMA configuration found
[    0.008621] Faking a node at [mem 0x0000000000000000-0x000000010effffff]
[    0.008633] NODE_DATA(0) allocated [mem 0x10efd5000-0x10effffff]
[    0.023795] Zone ranges:
[    0.023802]   DMA      [mem 0x0000000000001000-0x0000000000ffffff]
[    0.023807]   DMA32    [mem 0x0000000001000000-0x00000000ffffffff]
[    0.023810]   Normal   [mem 0x0000000100000000-0x000000010effffff]
[    0.023813]   Device   empty
[    0.023816] Movable zone start for each node
[    0.023822] Early memory node ranges
[    0.023822]   node   0: [mem 0x0000000000001000-0x000000000009efff]
[    0.023825]   node   0: [mem 0x0000000000100000-0x0000000009bfffff]
[    0.023826]   node   0: [mem 0x0000000009d81000-0x0000000009efffff]
[    0.023828]   node   0: [mem 0x0000000009f0b000-0x00000000c8aeffff]
[    0.023830]   node   0: [mem 0x00000000ce5fe000-0x00000000cf7fffff]
[    0.023831]   node   0: [mem 0x0000000100000000-0x000000010effffff]
[    0.023835] Initmem setup node 0 [mem 0x0000000000001000-0x000000010effffff]
[    0.023850] On node 0, zone DMA: 1 pages in unavailable ranges
[    0.023916] On node 0, zone DMA: 97 pages in unavailable ranges
[    0.024518] On node 0, zone DMA32: 385 pages in unavailable ranges
[    0.035507] On node 0, zone DMA32: 11 pages in unavailable ranges
[    0.035969] On node 0, zone DMA32: 23310 pages in unavailable ranges
[    0.036870] On node 0, zone Normal: 2048 pages in unavailable ranges
[    0.036942] On node 0, zone Normal: 4096 pages in unavailable ranges
[    0.037128] ACPI: PM-Timer IO Port: 0x408
[    0.037144] ACPI: LAPIC_NMI (acpi_id[0x00] high edge lint[0x1])
[    0.037146] ACPI: LAPIC_NMI (acpi_id[0x01] high edge lint[0x1])
[    0.037148] ACPI: LAPIC_NMI (acpi_id[0x02] high edge lint[0x1])
[    0.037150] ACPI: LAPIC_NMI (acpi_id[0x03] high edge lint[0x1])
[    0.037151] ACPI: LAPIC_NMI (acpi_id[0x04] high edge lint[0x1])
[    0.037152] ACPI: LAPIC_NMI (acpi_id[0x05] high edge lint[0x1])
[    0.037154] ACPI: LAPIC_NMI (acpi_id[0x06] high edge lint[0x1])
[    0.037155] ACPI: LAPIC_NMI (acpi_id[0x07] high edge lint[0x1])
[    0.037177] IOAPIC[0]: apic_id 32, version 33, address 0xfec00000, GSI 0-23
[    0.037186] IOAPIC[1]: apic_id 33, version 33, address 0xfec01000, GSI 24-55
[    0.037190] ACPI: INT_SRC_OVR (bus 0 bus_irq 0 global_irq 2 dfl dfl)
[    0.037193] ACPI: INT_SRC_OVR (bus 0 bus_irq 9 global_irq 9 low level)
[    0.037200] ACPI: Using ACPI (MADT) for SMP configuration information
[    0.037202] ACPI: HPET id: 0x43538210 base: 0xfed00000
[    0.037218] e820: update [mem 0xc4f93000-0xc500efff] usable ==> reserved
[    0.037239] smpboot: Allowing 16 CPUs, 12 hotplug CPUs
[    0.037275] PM: hibernation: Registered nosave memory: [mem 0x00000000-0x00000fff]
[    0.037278] PM: hibernation: Registered nosave memory: [mem 0x0009f000-0x0009ffff]
[    0.037280] PM: hibernation: Registered nosave memory: [mem 0x000a0000-0x000dffff]
[    0.037281] PM: hibernation: Registered nosave memory: [mem 0x000e0000-0x000fffff]
[    0.037284] PM: hibernation: Registered nosave memory: [mem 0x09c00000-0x09d80fff]
[    0.037287] PM: hibernation: Registered nosave memory: [mem 0x09f00000-0x09f0afff]
[    0.037289] PM: hibernation: Registered nosave memory: [mem 0xad492000-0xad492fff]
[    0.037292] PM: hibernation: Registered nosave memory: [mem 0xad49f000-0xad49ffff]
[    0.037295] PM: hibernation: Registered nosave memory: [mem 0xc4f93000-0xc500efff]
[    0.037297] PM: hibernation: Registered nosave memory: [mem 0xc8af0000-0xcc57dfff]
[    0.037299] PM: hibernation: Registered nosave memory: [mem 0xcc57e000-0xce57dfff]
[    0.037300] PM: hibernation: Registered nosave memory: [mem 0xce57e000-0xce5fdfff]
[    0.037303] PM: hibernation: Registered nosave memory: [mem 0xcf800000-0xcfffffff]
[    0.037304] PM: hibernation: Registered nosave memory: [mem 0xd0000000-0xf7ffffff]
[    0.037305] PM: hibernation: Registered nosave memory: [mem 0xf8000000-0xfbffffff]
[    0.037306] PM: hibernation: Registered nosave memory: [mem 0xfc000000-0xfd1fffff]
[    0.037308] PM: hibernation: Registered nosave memory: [mem 0xfd200000-0xfd2fffff]
[    0.037309] PM: hibernation: Registered nosave memory: [mem 0xfd300000-0xfed7ffff]
[    0.037310] PM: hibernation: Registered nosave memory: [mem 0xfed80000-0xfed80fff]
[    0.037311] PM: hibernation: Registered nosave memory: [mem 0xfed81000-0xffffffff]
[    0.037314] [mem 0xd0000000-0xf7ffffff] available for PCI devices
[    0.037317] Booting paravirtualized kernel on bare hardware
[    0.037321] clocksource: refined-jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 1910969940391419 ns
[    0.044745] setup_percpu: NR_CPUS:8192 nr_cpumask_bits:16 nr_cpu_ids:16 nr_node_ids:1
[    0.046105] percpu: Embedded 61 pages/cpu s212992 r8192 d28672 u262144
[    0.046124] pcpu-alloc: s212992 r8192 d28672 u262144 alloc=1*2097152
[    0.046129] pcpu-alloc: [0] 00 01 02 03 04 05 06 07 [0] 08 09 10 11 12 13 14 15 
[    0.046195] Fallback order for Node 0: 0 
[    0.046202] Built 1 zonelists, mobility grouping on.  Total pages: 873528
[    0.046204] Policy zone: Normal
[    0.046207] Kernel command line: BOOT_IMAGE=(hd0,gpt5)/vmlinuz-5.19.7-300.fc37.x86_64 root=UUID=401c1fb3-860c-469e-b303-427cc66e377d ro rhgb quiet
[    0.046353] Unknown kernel command line parameters "rhgb BOOT_IMAGE=(hd0,gpt5)/vmlinuz-5.19.7-300.fc37.x86_64", will be passed to user space.
[    0.047310] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
[    0.047723] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.048233] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.090273] Memory: 3286484K/3550224K available (16393K kernel code, 3177K rwdata, 11400K rodata, 3004K init, 4816K bss, 263480K reserved, 0K cma-reserved)
[    0.091330] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=16, Nodes=1
[    0.091377] ftrace: allocating 50346 entries in 197 pages
[    0.105080] ftrace: allocated 197 pages with 4 groups
[    0.106645] Dynamic Preempt: voluntary
[    0.106784] rcu: Preemptible hierarchical RCU implementation.
[    0.106785] rcu: 	RCU restricting CPUs from NR_CPUS=8192 to nr_cpu_ids=16.
[    0.106788] 	Trampoline variant of Tasks RCU enabled.
[    0.106789] 	Rude variant of Tasks RCU enabled.
[    0.106789] 	Tracing variant of Tasks RCU enabled.
[    0.106791] rcu: RCU calculated value of scheduler-enlistment delay is 100 jiffies.
[    0.106792] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=16
[    0.114342] NR_IRQS: 524544, nr_irqs: 1096, preallocated irqs: 16
[    0.114586] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.114712] kfence: initialized - using 2097152 bytes for 255 objects at 0x(____ptrval____)-0x(____ptrval____)
[    0.114751] random: crng init done
[    0.114793] Console: colour dummy device 80x25
[    0.114819] printk: console [tty0] enabled
[    0.114853] ACPI: Core revision 20220331
[    0.115135] clocksource: hpet: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 133484873504 ns
[    0.115163] APIC: Switch to symmetric I/O mode setup
[    0.116605] AMD-Vi: ivrs, add hid:AMDI0041, uid:, rdevid:152
[    0.117049] Switched APIC routing to physical flat.
[    0.118051] ..TIMER: vector=0x30 apic1=0 pin1=2 apic2=-1 pin2=-1
[    0.122171] clocksource: tsc-early: mask: 0xffffffffffffffff max_cycles: 0x1143c98f0b9, max_idle_ns: 440795256278 ns
[    0.122182] Calibrating delay loop (skipped), value calculated using timer frequency.. 2395.49 BogoMIPS (lpj=1197745)
[    0.122188] pid_max: default: 32768 minimum: 301
[    0.125013] LSM: Security Framework initializing
[    0.125035] Yama: becoming mindful.
[    0.125050] SELinux:  Initializing.
[    0.125095] LSM support for eBPF active
[    0.125098] landlock: Up and running.
[    0.125155] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.125174] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    0.125675] LVT offset 1 assigned for vector 0xf9
[    0.125771] LVT offset 2 assigned for vector 0xf4
[    0.125798] Last level iTLB entries: 4KB 1024, 2MB 1024, 4MB 512
[    0.125800] Last level dTLB entries: 4KB 1536, 2MB 1536, 4MB 768, 1GB 0
[    0.125809] Spectre V1 : Mitigation: usercopy/swapgs barriers and __user pointer sanitization
[    0.125813] Spectre V2 : Mitigation: Retpolines
[    0.125814] Spectre V2 : Spectre v2 / SpectreRSB mitigation: Filling RSB on context switch
[    0.125816] Spectre V2 : Spectre v2 / SpectreRSB : Filling RSB on VMEXIT
[    0.125817] Spectre V2 : Enabling Speculation Barrier for firmware calls
[    0.125818] RETBleed: Mitigation: untrained return thunk
[    0.125822] Spectre V2 : mitigation: Enabling conditional Indirect Branch Prediction Barrier
[    0.125824] Spectre V2 : User space: Mitigation: STIBP always-on protection
[    0.125826] Speculative Store Bypass: Mitigation: Speculative Store Bypass disabled via prctl
[    0.139294] Freeing SMP alternatives memory: 44K
[    0.241654] smpboot: CPU0: AMD 3015e with Radeon Graphics (family: 0x17, model: 0x20, stepping: 0x1)
[    0.241901] cblist_init_generic: Setting adjustable number of callback queues.
[    0.241906] cblist_init_generic: Setting shift to 4 and lim to 1.
[    0.241933] cblist_init_generic: Setting shift to 4 and lim to 1.
[    0.241958] cblist_init_generic: Setting shift to 4 and lim to 1.
[    0.241979] Performance Events: Fam17h+ core perfctr, AMD PMU driver.
[    0.241986] ... version:                0
[    0.241987] ... bit width:              48
[    0.241988] ... generic registers:      6
[    0.241989] ... value mask:             0000ffffffffffff
[    0.241991] ... max period:             00007fffffffffff
[    0.241992] ... fixed-purpose events:   0
[    0.241993] ... event mask:             000000000000003f
[    0.242106] rcu: Hierarchical SRCU implementation.
[    0.242107] rcu: 	Max phase no-delay instances is 400.
[    0.242319] NMI watchdog: Enabled. Permanently consumes one hw-PMU counter.
[    0.242588] smp: Bringing up secondary CPUs ...
[    0.242735] x86: Booting SMP configuration:
[    0.242737] .... node  #0, CPUs:        #1
[    0.243177] TSC synchronization [CPU#0 -> CPU#1]:
[    0.243177] Measured 1732462330 cycles TSC warp between CPUs, turning off TSC clock.
[    0.243177] tsc: Marking TSC unstable due to check_tsc_sync_source failed
[    0.244300] Spectre V2 : Update user space SMT mitigation: STIBP always-on
[    0.244359]   #2  #3
[    0.244540] smp: Brought up 1 node, 4 CPUs
[    0.245181] smpboot: Max logical packages: 4
[    0.245182] smpboot: Total of 4 processors activated (9581.96 BogoMIPS)
[    0.246331] devtmpfs: initialized
[    0.246331] x86/mm: Memory block size: 128MB
[    0.247246] ACPI: PM: Registering ACPI NVS region [mem 0x09f00000-0x09f0afff] (45056 bytes)
[    0.247246] ACPI: PM: Registering ACPI NVS region [mem 0xcc57e000-0xce57dfff] (33554432 bytes)
[    0.247842] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 1911260446275000 ns
[    0.247849] futex hash table entries: 4096 (order: 6, 262144 bytes, linear)
[    0.247939] pinctrl core: initialized pinctrl subsystem
[    0.248182] PM: RTC time: 15:58:55, date: 2022-11-07
[    0.248513] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.248645] DMA: preallocated 512 KiB GFP_KERNEL pool for atomic allocations
[    0.248651] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA pool for atomic allocations
[    0.248657] DMA: preallocated 512 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.248672] audit: initializing netlink subsys (disabled)
[    0.248683] audit: type=2000 audit(1667836735.133:1): state=initialized audit_enabled=0 res=1
[    0.248683] thermal_sys: Registered thermal governor 'fair_share'
[    0.248683] thermal_sys: Registered thermal governor 'bang_bang'
[    0.248683] thermal_sys: Registered thermal governor 'step_wise'
[    0.248683] thermal_sys: Registered thermal governor 'user_space'
[    0.248683] cpuidle: using governor menu
[    0.248683] HugeTLB: can optimize 4095 vmemmap pages for hugepages-1048576kB
[    0.248683] ACPI FADT declares the system doesn't support PCIe ASPM, so disable it
[    0.248683] acpiphp: ACPI Hot Plug PCI Controller Driver version: 0.5
[    0.248683] PCI: MMCONFIG for domain 0000 [bus 00-3f] at [mem 0xf8000000-0xfbffffff] (base 0xf8000000)
[    0.248683] PCI: MMCONFIG at [mem 0xf8000000-0xfbffffff] reserved in E820
[    0.249184] PCI: Using configuration type 1 for base access
[    0.251730] kprobes: kprobe jump-optimization is enabled. All kprobes are optimized if possible.
[    0.251756] HugeTLB: can optimize 7 vmemmap pages for hugepages-2048kB
[    0.251756] HugeTLB registered 1.00 GiB page size, pre-allocated 0 pages
[    0.251756] HugeTLB registered 2.00 MiB page size, pre-allocated 0 pages
[    0.252261] cryptd: max_cpu_qlen set to 1000
[    0.252277] raid6: skipped pq benchmark and selected avx2x4
[    0.252277] raid6: using avx2x2 recovery algorithm
[    0.252377] ACPI: Added _OSI(Module Device)
[    0.252381] ACPI: Added _OSI(Processor Device)
[    0.252383] ACPI: Added _OSI(3.0 _SCP Extensions)
[    0.252385] ACPI: Added _OSI(Processor Aggregator Device)
[    0.252388] ACPI: Added _OSI(Linux-Dell-Video)
[    0.252390] ACPI: Added _OSI(Linux-Lenovo-NV-HDMI-Audio)
[    0.252393] ACPI: Added _OSI(Linux-HPI-Hybrid-Graphics)
[    0.267939] ACPI: 10 ACPI AML tables successfully acquired and loaded
[    0.270637] ACPI: [Firmware Bug]: BIOS _OSI(Linux) query ignored
[    0.273384] ACPI: EC: EC started
[    0.273386] ACPI: EC: interrupt blocked
[    0.273520] ACPI: EC: EC_CMD/EC_SC=0x666, EC_DATA=0x662
[    0.273523] ACPI: \_SB_.PCI0.LPC0.H_EC: Boot DSDT EC used to handle transactions
[    0.273526] ACPI: Interpreter enabled
[    0.273546] ACPI: PM: (supports S0 S3 S4 S5)
[    0.273548] ACPI: Using IOAPIC for interrupt routing
[    0.273701] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
[    0.273703] PCI: Using E820 reservations for host bridge windows
[    0.274039] ACPI: Enabled 4 GPEs in block 00 to 1F
[    0.284177] ACPI: PCI Root Bridge [PCI0] (domain 0000 [bus 00-ff])
[    0.284177] acpi PNP0A08:00: _OSC: OS supports [ExtendedConfig ASPM ClockPM Segments MSI EDR HPX-Type3]
[    0.284177] acpi PNP0A08:00: _OSC: platform does not support [SHPCHotplug LTR DPC]
[    0.284177] acpi PNP0A08:00: _OSC: OS now controls [PCIeHotplug PME AER PCIeCapability]
[    0.284177] acpi PNP0A08:00: FADT indicates ASPM is unsupported, using BIOS configuration
[    0.284177] acpi PNP0A08:00: [Firmware Info]: MMCONFIG for domain 0000 [bus 00-3f] only partially covers this bridge
[    0.284177] PCI host bridge to bus 0000:00
[    0.284177] pci_bus 0000:00: root bus resource [mem 0x000a0000-0x000effff window]
[    0.284177] pci_bus 0000:00: root bus resource [mem 0xd0000000-0xf7ffffff window]
[    0.284177] pci_bus 0000:00: root bus resource [mem 0xfc000000-0xfdffffff window]
[    0.284177] pci_bus 0000:00: root bus resource [mem 0x130000000-0xffffffffff window]
[    0.284177] pci_bus 0000:00: root bus resource [io  0x0000-0x0cf7 window]
[    0.284177] pci_bus 0000:00: root bus resource [io  0x0d00-0xffff window]
[    0.284177] pci_bus 0000:00: root bus resource [bus 00-ff]
[    0.284177] pci 0000:00:00.0: [1022:15d0] type 00 class 0x060000
[    0.284177] pci 0000:00:00.2: [1022:15d1] type 00 class 0x080600
[    0.284177] pci 0000:00:01.0: [1022:1452] type 00 class 0x060000
[    0.284182] pci 0000:00:01.2: [1022:15d3] type 01 class 0x060400
[    0.284286] pci 0000:00:01.2: enabling Extended Tags
[    0.284451] pci 0000:00:01.2: PME# supported from D0 D3hot D3cold
[    0.284719] pci 0000:00:01.6: [1022:15d3] type 01 class 0x060400
[    0.284822] pci 0000:00:01.6: enabling Extended Tags
[    0.284998] pci 0000:00:01.6: PME# supported from D0 D3hot D3cold
[    0.285272] pci 0000:00:08.0: [1022:1452] type 00 class 0x060000
[    0.285373] pci 0000:00:08.1: [1022:15db] type 01 class 0x060400
[    0.285419] pci 0000:00:08.1: enabling Extended Tags
[    0.285478] pci 0000:00:08.1: PME# supported from D0 D3hot D3cold
[    0.285611] pci 0000:00:08.2: [1022:15dc] type 01 class 0x060400
[    0.285657] pci 0000:00:08.2: enabling Extended Tags
[    0.285718] pci 0000:00:08.2: PME# supported from D0 D3hot D3cold
[    0.285888] pci 0000:00:14.0: [1022:790b] type 00 class 0x0c0500
[    0.286047] pci 0000:00:14.3: [1022:790e] type 00 class 0x060100
[    0.286243] pci 0000:00:18.0: [1022:15e8] type 00 class 0x060000
[    0.286306] pci 0000:00:18.1: [1022:15e9] type 00 class 0x060000
[    0.286366] pci 0000:00:18.2: [1022:15ea] type 00 class 0x060000
[    0.286431] pci 0000:00:18.3: [1022:15eb] type 00 class 0x060000
[    0.286492] pci 0000:00:18.4: [1022:15ec] type 00 class 0x060000
[    0.286544] pci 0000:00:18.5: [1022:15ed] type 00 class 0x060000
[    0.286595] pci 0000:00:18.6: [1022:15ee] type 00 class 0x060000
[    0.286646] pci 0000:00:18.7: [1022:15ef] type 00 class 0x060000
[    0.287108] pci 0000:01:00.0: [168c:003e] type 00 class 0x028000
[    0.288363] pci 0000:01:00.0: reg 0x10: [mem 0xfc000000-0xfc1fffff 64bit]
[    0.289735] pci 0000:01:00.0: PME# supported from D0 D3hot D3cold
[    0.290985] pci 0000:00:01.2: PCI bridge to [bus 01]
[    0.291001] pci 0000:00:01.2:   bridge window [mem 0xfc000000-0xfc1fffff]
[    0.291206] pci 0000:02:00.0: [1217:8621] type 00 class 0x080501
[    0.291227] pci 0000:02:00.0: reg 0x10: [mem 0xfc701000-0xfc701fff]
[    0.291237] pci 0000:02:00.0: reg 0x14: [mem 0xfc700000-0xfc7007ff]
[    0.291374] pci 0000:02:00.0: PME# supported from D3hot D3cold
[    0.294227] pci 0000:00:01.6: PCI bridge to [bus 02]
[    0.294238] pci 0000:00:01.6:   bridge window [mem 0xfc700000-0xfc7fffff]
[    0.294373] pci 0000:03:00.0: [1002:15d8] type 00 class 0x030000
[    0.294394] pci 0000:03:00.0: reg 0x10: [mem 0x130000000-0x13fffffff 64bit pref]
[    0.294408] pci 0000:03:00.0: reg 0x18: [mem 0x140000000-0x1401fffff 64bit pref]
[    0.294418] pci 0000:03:00.0: reg 0x20: [io  0x1000-0x10ff]
[    0.294427] pci 0000:03:00.0: reg 0x24: [mem 0xfc600000-0xfc67ffff]
[    0.294442] pci 0000:03:00.0: enabling Extended Tags
[    0.294463] pci 0000:03:00.0: BAR 0: assigned to efifb
[    0.294530] pci 0000:03:00.0: PME# supported from D1 D2 D3hot D3cold
[    0.294692] pci 0000:03:00.1: [1002:15de] type 00 class 0x040300
[    0.294706] pci 0000:03:00.1: reg 0x10: [mem 0xfc6c8000-0xfc6cbfff]
[    0.294744] pci 0000:03:00.1: enabling Extended Tags
[    0.294795] pci 0000:03:00.1: PME# supported from D1 D2 D3hot D3cold
[    0.294918] pci 0000:03:00.2: [1022:15df] type 00 class 0x108000
[    0.294945] pci 0000:03:00.2: reg 0x18: [mem 0xfc500000-0xfc5fffff]
[    0.294964] pci 0000:03:00.2: reg 0x24: [mem 0xfc6ce000-0xfc6cffff]
[    0.294978] pci 0000:03:00.2: enabling Extended Tags
[    0.295141] pci 0000:03:00.3: [1022:15e5] type 00 class 0x0c0330
[    0.295141] pci 0000:03:00.3: reg 0x10: [mem 0xfc300000-0xfc3fffff 64bit]
[    0.295141] pci 0000:03:00.3: enabling Extended Tags
[    0.295141] pci 0000:03:00.3: PME# supported from D0 D3hot D3cold
[    0.295141] pci 0000:03:00.5: [1022:15e2] type 00 class 0x048000
[    0.295141] pci 0000:03:00.5: reg 0x10: [mem 0xfc680000-0xfc6bffff]
[    0.295141] pci 0000:03:00.5: enabling Extended Tags
[    0.295141] pci 0000:03:00.5: PME# supported from D0 D3hot D3cold
[    0.295141] pci 0000:03:00.6: [1022:15e3] type 00 class 0x040300
[    0.295141] pci 0000:03:00.6: reg 0x10: [mem 0xfc6c0000-0xfc6c7fff]
[    0.295141] pci 0000:03:00.6: enabling Extended Tags
[    0.295141] pci 0000:03:00.6: PME# supported from D0 D3hot D3cold
[    0.295141] pci 0000:03:00.7: [1022:15e4] type 00 class 0x000000
[    0.295141] pci 0000:03:00.7: reg 0x18: [mem 0xfc400000-0xfc4fffff]
[    0.295141] pci 0000:03:00.7: reg 0x24: [mem 0xfc6cc000-0xfc6cdfff]
[    0.295141] pci 0000:03:00.7: enabling Extended Tags
[    0.295141] pci 0000:00:08.1: PCI bridge to [bus 03]
[    0.295141] pci 0000:00:08.1:   bridge window [io  0x1000-0x1fff]
[    0.295145] pci 0000:00:08.1:   bridge window [mem 0xfc300000-0xfc6fffff]
[    0.295151] pci 0000:00:08.1:   bridge window [mem 0x130000000-0x381617aa401fffff 64bit pref]
[    0.295235] pci 0000:04:00.0: [1022:7901] type 00 class 0x010601
[    0.295293] pci 0000:04:00.0: reg 0x24: [mem 0xfc200000-0xfc2007ff]
[    0.295310] pci 0000:04:00.0: enabling Extended Tags
[    0.295384] pci 0000:04:00.0: PME# supported from D3hot D3cold
[    0.295546] pci 0000:00:08.2: PCI bridge to [bus 04]
[    0.295554] pci 0000:00:08.2:   bridge window [mem 0xfc200000-0xfc2fffff]
[    0.295768] ACPI: PCI: Interrupt link LNKA configured for IRQ 0
[    0.295846] ACPI: PCI: Interrupt link LNKB configured for IRQ 0
[    0.295903] ACPI: PCI: Interrupt link LNKC configured for IRQ 0
[    0.295977] ACPI: PCI: Interrupt link LNKD configured for IRQ 0
[    0.296046] ACPI: PCI: Interrupt link LNKE configured for IRQ 0
[    0.296098] ACPI: PCI: Interrupt link LNKF configured for IRQ 0
[    0.296151] ACPI: PCI: Interrupt link LNKG configured for IRQ 0
[    0.296217] ACPI: PCI: Interrupt link LNKH configured for IRQ 0
[    0.301040] ACPI: EC: interrupt unblocked
[    0.301042] ACPI: EC: event unblocked
[    0.301054] ACPI: EC: EC_CMD/EC_SC=0x666, EC_DATA=0x662
[    0.301055] ACPI: EC: GPE=0x4
[    0.301057] ACPI: \_SB_.PCI0.LPC0.H_EC: Boot DSDT EC initialization complete
[    0.301060] ACPI: \_SB_.PCI0.LPC0.H_EC: EC: Used to handle transactions and events
[    0.302183] iommu: Default domain type: Translated 
[    0.302186] iommu: DMA domain TLB invalidation policy: lazy mode 
[    0.302316] SCSI subsystem initialized
[    0.302326] libata version 3.00 loaded.
[    0.302326] ACPI: bus type USB registered
[    0.302326] usbcore: registered new interface driver usbfs
[    0.302326] usbcore: registered new interface driver hub
[    0.302326] usbcore: registered new device driver usb
[    0.307647] pps_core: LinuxPPS API ver. 1 registered
[    0.307650] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.307655] PTP clock support registered
[    0.308211] EDAC MC: Ver: 3.0.0
[    0.308374] Registered efivars operations
[    0.308374] NetLabel: Initializing
[    0.308374] NetLabel:  domain hash size = 128
[    0.308374] NetLabel:  protocols = UNLABELED CIPSOv4 CALIPSO
[    0.308374] NetLabel:  unlabeled traffic allowed by default
[    0.308374] mctp: management component transport protocol core
[    0.308374] NET: Registered PF_MCTP protocol family
[    0.308374] PCI: Using ACPI for IRQ routing
[    0.310693] PCI: pci_cache_line_size set to 64 bytes
[    0.310698] pci 0000:00:08.1: can't claim BAR 15 [mem 0x130000000-0x381617aa401fffff 64bit pref]: no compatible bridge window
[    0.310703] pci 0000:00:08.1: [mem 0x130000000-0x381617aa401fffff 64bit pref] clipped to [mem 0x130000000-0xffffffffff 64bit pref]
[    0.310712] pci 0000:00:08.1:   bridge window [mem 0x130000000-0xffffffffff 64bit pref]
[    0.310912] e820: reserve RAM buffer [mem 0x0009f000-0x0009ffff]
[    0.310915] e820: reserve RAM buffer [mem 0x09c00000-0x0bffffff]
[    0.310917] e820: reserve RAM buffer [mem 0x09f00000-0x0bffffff]
[    0.310919] e820: reserve RAM buffer [mem 0xad492018-0xafffffff]
[    0.310921] e820: reserve RAM buffer [mem 0xc4f93000-0xc7ffffff]
[    0.310922] e820: reserve RAM buffer [mem 0xc8af0000-0xcbffffff]
[    0.310924] e820: reserve RAM buffer [mem 0xcf800000-0xcfffffff]
[    0.310925] e820: reserve RAM buffer [mem 0x10f000000-0x10fffffff]
[    0.311212] pci 0000:03:00.0: vgaarb: setting as boot VGA device
[    0.311212] pci 0000:03:00.0: vgaarb: bridge control possible
[    0.311212] pci 0000:03:00.0: vgaarb: VGA device added: decodes=io+mem,owns=none,locks=none
[    0.311212] vgaarb: loaded
[    0.311256] hpet0: at MMIO 0xfed00000, IRQs 2, 8, 0
[    0.311263] hpet0: 3 comparators, 32-bit 14.318180 MHz counter
[    0.313247] clocksource: Switched to clocksource hpet
[    0.313466] VFS: Disk quotas dquot_6.6.0
[    0.313487] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
[    0.313601] pnp: PnP ACPI init
[    0.313813] system 00:00: [io  0x0f50-0x0f51] has been reserved
[    0.313819] system 00:00: [mem 0xfec00000-0xfec01fff] could not be reserved
[    0.313824] system 00:00: [mem 0xfee00000-0xfee00fff] has been reserved
[    0.313828] system 00:00: [mem 0xf8000000-0xfbffffff] has been reserved
[    0.314278] system 00:03: [io  0x0400-0x04cf] has been reserved
[    0.314283] system 00:03: [io  0x04d0-0x04d1] has been reserved
[    0.314286] system 00:03: [io  0x04d6] has been reserved
[    0.314289] system 00:03: [io  0x0c00-0x0c01] has been reserved
[    0.314292] system 00:03: [io  0x0c14] has been reserved
[    0.314295] system 00:03: [io  0x0c50-0x0c52] has been reserved
[    0.314298] system 00:03: [io  0x0c6c] has been reserved
[    0.314301] system 00:03: [io  0x0c6f] has been reserved
[    0.314304] system 00:03: [io  0x0cd0-0x0cdb] has been reserved
[    0.314441] system 00:04: [mem 0x000e0000-0x000fffff] could not be reserved
[    0.314447] system 00:04: [mem 0xff000000-0xffffffff] has been reserved
[    0.314451] system 00:04: [mem 0xfec10000-0xfec1001f] has been reserved
[    0.314455] system 00:04: [mem 0xfed00000-0xfed003ff] has been reserved
[    0.314459] system 00:04: [mem 0xfed61000-0xfed613ff] has been reserved
[    0.314463] system 00:04: [mem 0xfed80000-0xfed80fff] has been reserved
[    0.316266] pnp: PnP ACPI: found 5 devices
[    0.326002] clocksource: acpi_pm: mask: 0xffffff max_cycles: 0xffffff, max_idle_ns: 2085701024 ns
[    0.326125] NET: Registered PF_INET protocol family
[    0.326304] IP idents hash table entries: 65536 (order: 7, 524288 bytes, linear)
[    0.328066] tcp_listen_portaddr_hash hash table entries: 2048 (order: 3, 32768 bytes, linear)
[    0.328084] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.328093] TCP established hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.328234] TCP bind hash table entries: 32768 (order: 7, 524288 bytes, linear)
[    0.328384] TCP: Hash tables configured (established 32768 bind 32768)
[    0.328590] MPTCP token hash table entries: 4096 (order: 4, 98304 bytes, linear)
[    0.328620] UDP hash table entries: 2048 (order: 4, 65536 bytes, linear)
[    0.328641] UDP-Lite hash table entries: 2048 (order: 4, 65536 bytes, linear)
[    0.328734] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.328747] NET: Registered PF_XDP protocol family
[    0.328772] pci 0000:00:01.2: PCI bridge to [bus 01]
[    0.328784] pci 0000:00:01.2:   bridge window [mem 0xfc000000-0xfc1fffff]
[    0.328795] pci 0000:00:01.6: PCI bridge to [bus 02]
[    0.328801] pci 0000:00:01.6:   bridge window [mem 0xfc700000-0xfc7fffff]
[    0.328815] pci 0000:00:08.1: PCI bridge to [bus 03]
[    0.328823] pci 0000:00:08.1:   bridge window [io  0x1000-0x1fff]
[    0.328829] pci 0000:00:08.1:   bridge window [mem 0xfc300000-0xfc6fffff]
[    0.328833] pci 0000:00:08.1:   bridge window [mem 0x130000000-0xffffffffff 64bit pref]
[    0.328841] pci 0000:00:08.2: PCI bridge to [bus 04]
[    0.328846] pci 0000:00:08.2:   bridge window [mem 0xfc200000-0xfc2fffff]
[    0.328858] pci_bus 0000:00: resource 4 [mem 0x000a0000-0x000effff window]
[    0.328862] pci_bus 0000:00: resource 5 [mem 0xd0000000-0xf7ffffff window]
[    0.328865] pci_bus 0000:00: resource 6 [mem 0xfc000000-0xfdffffff window]
[    0.328868] pci_bus 0000:00: resource 7 [mem 0x130000000-0xffffffffff window]
[    0.328871] pci_bus 0000:00: resource 8 [io  0x0000-0x0cf7 window]
[    0.328873] pci_bus 0000:00: resource 9 [io  0x0d00-0xffff window]
[    0.328876] pci_bus 0000:01: resource 1 [mem 0xfc000000-0xfc1fffff]
[    0.328880] pci_bus 0000:02: resource 1 [mem 0xfc700000-0xfc7fffff]
[    0.328883] pci_bus 0000:03: resource 0 [io  0x1000-0x1fff]
[    0.328886] pci_bus 0000:03: resource 1 [mem 0xfc300000-0xfc6fffff]
[    0.328888] pci_bus 0000:03: resource 2 [mem 0x130000000-0xffffffffff 64bit pref]
[    0.328892] pci_bus 0000:04: resource 1 [mem 0xfc200000-0xfc2fffff]
[    0.329204] pci 0000:03:00.1: D0 power state depends on 0000:03:00.0
[    0.329680] PCI: CLS 32 bytes, default 64
[    0.329700] pci 0000:00:00.2: AMD-Vi: IOMMU performance counters supported
[    0.329781] Trying to unpack rootfs image as initramfs...
[    0.329806] pci 0000:00:00.2: can't derive routing for PCI INT A
[    0.329809] pci 0000:00:00.2: PCI INT A: not connected
[    0.329846] pci 0000:00:01.0: Adding to iommu group 0
[    0.329866] pci 0000:00:01.2: Adding to iommu group 1
[    0.329889] pci 0000:00:01.6: Adding to iommu group 2
[    0.329917] pci 0000:00:08.0: Adding to iommu group 3
[    0.329936] pci 0000:00:08.1: Adding to iommu group 4
[    0.329957] pci 0000:00:08.2: Adding to iommu group 5
[    0.329990] pci 0000:00:14.0: Adding to iommu group 6
[    0.330007] pci 0000:00:14.3: Adding to iommu group 6
[    0.330072] pci 0000:00:18.0: Adding to iommu group 7
[    0.330088] pci 0000:00:18.1: Adding to iommu group 7
[    0.330105] pci 0000:00:18.2: Adding to iommu group 7
[    0.330122] pci 0000:00:18.3: Adding to iommu group 7
[    0.330139] pci 0000:00:18.4: Adding to iommu group 7
[    0.330159] pci 0000:00:18.5: Adding to iommu group 7
[    0.330176] pci 0000:00:18.6: Adding to iommu group 7
[    0.330217] pci 0000:00:18.7: Adding to iommu group 7
[    0.330240] pci 0000:01:00.0: Adding to iommu group 8
[    0.330270] pci 0000:02:00.0: Adding to iommu group 9
[    0.330311] pci 0000:03:00.0: Adding to iommu group 10
[    0.330376] pci 0000:03:00.1: Adding to iommu group 11
[    0.330404] pci 0000:03:00.2: Adding to iommu group 11
[    0.330427] pci 0000:03:00.3: Adding to iommu group 11
[    0.330449] pci 0000:03:00.5: Adding to iommu group 11
[    0.330472] pci 0000:03:00.6: Adding to iommu group 11
[    0.330494] pci 0000:03:00.7: Adding to iommu group 11
[    0.330517] pci 0000:04:00.0: Adding to iommu group 12
[    0.333887] platform AMDI0041:00: Adding to iommu group 13
[    0.334757] pci 0000:00:00.2: AMD-Vi: Found IOMMU cap 0x40
[    0.334762] AMD-Vi: Extended features (0x4f77ef22294ada): PPR NX GT IA GA PC GA_vAPIC
[    0.334776] AMD-Vi: Interrupt remapping enabled
[    0.334777] AMD-Vi: Virtual APIC enabled
[    0.335044] PCI-DMA: Using software bounce buffering for IO (SWIOTLB)
[    0.335047] software IO TLB: mapped [mem 0x00000000c080d000-0x00000000c480d000] (64MB)
[    0.335155] amd_uncore: 4  amd_df counters detected
[    0.335164] amd_uncore: 6  amd_l3 counters detected
[    0.335926] perf/amd_iommu: Detected AMD IOMMU #0 (2 banks, 4 counters/bank).
[    0.338444] Initialise system trusted keyrings
[    0.338463] Key type blacklist registered
[    0.338570] workingset: timestamp_bits=36 max_order=20 bucket_order=0
[    0.341414] zbud: loaded
[    0.342650] integrity: Platform Keyring initialized
[    0.342658] integrity: Machine keyring initialized
[    0.355414] NET: Registered PF_ALG protocol family
[    0.355419] xor: automatically using best checksumming function   avx       
[    0.355423] Key type asymmetric registered
[    0.355424] Asymmetric key parser 'x509' registered
[    0.895281] Freeing initrd memory: 47972K
[    0.901135] alg: self-tests for CTR-KDF (hmac(sha256)) passed
[    0.901244] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
[    0.901387] io scheduler mq-deadline registered
[    0.901391] io scheduler kyber registered
[    0.901455] io scheduler bfq registered
[    0.903872] atomic64_test: passed for x86-64 platform with CX8 and with SSE
[    0.905679] pcieport 0000:00:01.2: PME: Signaling with IRQ 26
[    0.905891] pcieport 0000:00:01.2: AER: enabled with IRQ 26
[    0.906257] pcieport 0000:00:01.6: PME: Signaling with IRQ 27
[    0.906466] pcieport 0000:00:01.6: AER: enabled with IRQ 27
[    0.906748] pcieport 0000:00:08.1: PME: Signaling with IRQ 28
[    0.907032] pcieport 0000:00:08.2: PME: Signaling with IRQ 29
[    0.907228] pcieport 0000:00:08.2: AER: enabled with IRQ 29
[    0.907385] shpchp: Standard Hot Plug PCI Controller Driver version: 0.4
[    0.908885] ACPI: AC: AC Adapter [ADP1] (off-line)
[    0.908945] input: Power Button as /devices/LNXSYSTM:00/LNXSYBUS:00/PNP0C0C:00/input/input0
[    0.908970] ACPI: button: Power Button [PWRB]
[    0.909014] input: Lid Switch as /devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:28/PNP0C09:00/PNP0C0D:00/input/input1
[    0.909037] ACPI: button: Lid Switch [LID0]
[    0.909075] input: Power Button as /devices/LNXSYSTM:00/LNXPWRBN:00/input/input2
[    0.909147] ACPI: button: Power Button [PWRF]
[    0.909240] Monitor-Mwait will be used to enter C-1 state
[    0.909256] ACPI: \_PR_.C000: Found 2 idle states
[    0.909365] ACPI: \_PR_.C001: Found 2 idle states
[    0.909488] ACPI: \_PR_.C002: Found 2 idle states
[    0.909611] ACPI: \_PR_.C003: Found 2 idle states
[    0.909989] thermal LNXTHERM:00: registered as thermal_zone0
[    0.909992] ACPI: thermal: Thermal Zone [TZ01] (20 C)
[    0.910474] Serial: 8250/16550 driver, 32 ports, IRQ sharing enabled
[    0.915598] AMDI0020:00: ttyS4 at MMIO 0xfedc9000 (irq = 3, base_baud = 3000000) is a 16550A
[    0.916331] Non-volatile memory driver v1.3
[    0.916340] Linux agpgart interface v0.103
[    0.919086] tpm_tis NTC0702:00: 2.0 TPM (device-id 0xFC, rev-id 1)
[    0.933989] ACPI: bus type drm_connector registered
[    0.935169] ahci 0000:04:00.0: version 3.0
[    0.937674] ACPI: battery: Slot [BAT0] (battery present)
[    0.945800] ahci 0000:04:00.0: AHCI 0001.0301 32 slots 1 ports 6 Gbps 0x1 impl SATA mode
[    0.945814] ahci 0000:04:00.0: flags: 64bit ncq sntf ilck pm led clo only pmp fbs pio slum part 
[    0.946448] scsi host0: ahci
[    0.946596] ata1: SATA max UDMA/133 abar m2048@0xfc200000 port 0xfc200100 irq 31
[    0.947195] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    0.947204] ehci-pci: EHCI PCI platform driver
[    0.947242] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
[    0.947247] ohci-pci: OHCI PCI platform driver
[    0.947265] uhci_hcd: USB Universal Host Controller Interface driver
[    0.947565] xhci_hcd 0000:03:00.3: xHCI Host Controller
[    0.947665] xhci_hcd 0000:03:00.3: new USB bus registered, assigned bus number 1
[    0.947948] xhci_hcd 0000:03:00.3: hcc params 0x0278ffe5 hci version 0x110 quirks 0x0000004000000490
[    0.948467] xhci_hcd 0000:03:00.3: xHCI Host Controller
[    0.948576] xhci_hcd 0000:03:00.3: new USB bus registered, assigned bus number 2
[    0.948581] xhci_hcd 0000:03:00.3: Host supports USB 3.1 Enhanced SuperSpeed
[    0.948727] usb usb1: New USB device found, idVendor=1d6b, idProduct=0002, bcdDevice= 5.19
[    0.948731] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    0.948733] usb usb1: Product: xHCI Host Controller
[    0.948735] usb usb1: Manufacturer: Linux 5.19.7-300.fc37.x86_64 xhci-hcd
[    0.948737] usb usb1: SerialNumber: 0000:03:00.3
[    0.948914] hub 1-0:1.0: USB hub found
[    0.948933] hub 1-0:1.0: 6 ports detected
[    0.949552] usb usb2: We don't know the algorithms for LPM for this host, disabling LPM.
[    0.949583] usb usb2: New USB device found, idVendor=1d6b, idProduct=0003, bcdDevice= 5.19
[    0.949586] usb usb2: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    0.949588] usb usb2: Product: xHCI Host Controller
[    0.949590] usb usb2: Manufacturer: Linux 5.19.7-300.fc37.x86_64 xhci-hcd
[    0.949592] usb usb2: SerialNumber: 0000:03:00.3
[    0.949721] hub 2-0:1.0: USB hub found
[    0.949733] hub 2-0:1.0: 4 ports detected
[    0.950310] usbcore: registered new interface driver usbserial_generic
[    0.950319] usbserial: USB Serial support registered for generic
[    0.950351] i8042: PNP: PS/2 Controller [PNP0303:KBC0] at 0x60,0x64 irq 1
[    0.950354] i8042: PNP: PS/2 appears to have AUX port disabled, if this is incorrect please boot with i8042.nopnp
[    0.951106] serio: i8042 KBD port at 0x60,0x64 irq 1
[    0.951219] mousedev: PS/2 mouse device common for all mice
[    0.951452] rtc_cmos 00:01: RTC can wake from S4
[    0.951871] rtc_cmos 00:01: registered as rtc0
[    0.951923] rtc_cmos 00:01: setting system clock to 2022-11-07T15:58:56 UTC (1667836736)
[    0.951946] rtc_cmos 00:01: alarms up to one month, y3k, 114 bytes nvram, hpet irqs
[    0.951971] device-mapper: core: CONFIG_IMA_DISABLE_HTABLE is disabled. Duplicate IMA measurements will not be recorded in the IMA log.
[    0.951995] device-mapper: uevent: version 1.0.3
[    0.952086] device-mapper: ioctl: 4.47.0-ioctl (2022-07-28) initialised: dm-devel@redhat.com
[    0.952656] [drm] Initialized simpledrm 1.0.0 20200625 for simple-framebuffer.0 on minor 0
[    0.953704] fbcon: Deferring console take-over
[    0.953712] simple-framebuffer simple-framebuffer.0: [drm] fb0: simpledrmdrmfb frame buffer device
[    0.953826] hid: raw HID events driver (C) Jiri Kosina
[    0.953900] usbcore: registered new interface driver usbhid
[    0.953902] usbhid: USB HID core driver
[    0.954173] drop_monitor: Initializing network drop monitor service
[    0.964616] input: AT Translated Set 2 keyboard as /devices/platform/i8042/serio0/input/input3
[    0.972202] Initializing XFRM netlink socket
[    0.972415] NET: Registered PF_INET6 protocol family
[    0.977900] Segment Routing with IPv6
[    0.977905] RPL Segment Routing with IPv6
[    0.977918] In-situ OAM (IOAM) with IPv6
[    0.977951] mip6: Mobile IPv6
[    0.977953] NET: Registered PF_PACKET protocol family
[    0.978786] microcode: CPU0: patch_level=0x08200103
[    0.978798] microcode: CPU1: patch_level=0x08200103
[    0.978812] microcode: CPU2: patch_level=0x08200103
[    0.978822] microcode: CPU3: patch_level=0x08200103
[    0.978828] microcode: Microcode Update Driver: v2.2.
[    0.978842] IPI shorthand broadcast: enabled
[    0.978856] AVX2 version of gcm_enc/dec engaged.
[    0.978998] AES CTR mode by8 optimization enabled
[    0.979854] registered taskstats version 1
[    0.980060] Loading compiled-in X.509 certificates
[    1.013926] Loaded X.509 cert 'Fedora kernel signing key: a45ef2ef861c6046fbb05f116d57c39a66a50242'
[    1.014601] zswap: loaded using pool lzo/zbud
[    1.014766] page_owner is disabled
[    1.014864] Key type ._fscrypt registered
[    1.014867] Key type .fscrypt registered
[    1.014869] Key type fscrypt-provisioning registered
[    1.015441] Btrfs loaded, crc32c=crc32c-generic, zoned=yes, fsverity=yes
[    1.015464] Key type big_key registered
[    1.015744] Key type trusted registered
[    1.020304] Key type encrypted registered
[    1.020918] integrity: Loading X.509 certificate: UEFI:db
[    1.020968] integrity: Loaded X.509 cert 'Microsoft Windows Production PCA 2011: a92902398e16c49778cd90f99e4f9ae17c55af53'
[    1.020970] integrity: Loading X.509 certificate: UEFI:db
[    1.020998] integrity: Loaded X.509 cert 'Microsoft Corporation UEFI CA 2011: 13adbf4309bd82709c8cd54f316ed522988a1bd4'
[    1.022765] Loading compiled-in module X.509 certificates
[    1.023476] Loaded X.509 cert 'Fedora kernel signing key: a45ef2ef861c6046fbb05f116d57c39a66a50242'
[    1.023481] ima: Allocated hash algorithm: sha256
[    1.058091] ima: No architecture policies found
[    1.058146] evm: Initialising EVM extended attributes:
[    1.058148] evm: security.selinux
[    1.058150] evm: security.SMACK64 (disabled)
[    1.058151] evm: security.SMACK64EXEC (disabled)
[    1.058152] evm: security.SMACK64TRANSMUTE (disabled)
[    1.058153] evm: security.SMACK64MMAP (disabled)
[    1.058154] evm: security.apparmor (disabled)
[    1.058155] evm: security.ima
[    1.058156] evm: security.capability
[    1.058157] evm: HMAC attrs: 0x1
[    1.114032] alg: No test for 842 (842-scomp)
[    1.114101] alg: No test for 842 (842-generic)
[    1.189208] usb 1-5: new full-speed USB device number 2 using xhci_hcd
[    1.254580] PM:   Magic number: 14:589:992
[    1.254806] RAS: Correctable Errors collector initialized.
[    1.254842] Unstable clock detected, switching default tracing clock to "global"
               If you want to keep using the local clock, then add:
                 "trace_clock=local"
               on the kernel command line
[    1.257440] ata1: SATA link down (SStatus 0 SControl 300)
[    1.259550] Freeing unused decrypted memory: 2036K
[    1.260931] Freeing unused kernel image (initmem) memory: 3004K
[    1.267207] Write protecting the kernel read-only data: 30720k
[    1.268158] Freeing unused kernel image (text/rodata gap) memory: 2036K
[    1.268518] Freeing unused kernel image (rodata/data gap) memory: 888K
[    1.339690] x86/mm: Checked W+X mappings: passed, no W+X pages found.
[    1.339701] rodata_test: all tests were successful
[    1.339711] Run /init as init process
[    1.339714]   with arguments:
[    1.339716]     /init
[    1.339718]     rhgb
[    1.339719]   with environment:
[    1.339720]     HOME=/
[    1.339721]     TERM=linux
[    1.339722]     BOOT_IMAGE=(hd0,gpt5)/vmlinuz-5.19.7-300.fc37.x86_64
[    1.344960] usb 1-5: New USB device found, idVendor=0cf3, idProduct=e300, bcdDevice= 0.01
[    1.344969] usb 1-5: New USB device strings: Mfr=0, Product=0, SerialNumber=0
[    1.388859] systemd[1]: systemd 251.4-53.fc37 running in system mode (+PAM +AUDIT +SELINUX -APPARMOR +IMA +SMACK +SECCOMP -GCRYPT +GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN -IPTC +KMOD +LIBCRYPTSETUP +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +XKBCOMMON +UTMP +SYSVINIT default-hierarchy=unified)
[    1.388870] systemd[1]: Detected architecture x86-64.
[    1.388875] systemd[1]: Running in initial RAM disk.
[    1.388939] systemd[1]: No hostname configured, using default hostname.
[    1.389045] systemd[1]: Hostname set to <fedora>.
[    1.468267] usb 1-6: new high-speed USB device number 3 using xhci_hcd
[    1.620293] usb 1-6: New USB device found, idVendor=04f2, idProduct=b6d3, bcdDevice=10.69
[    1.620303] usb 1-6: New USB device strings: Mfr=3, Product=1, SerialNumber=2
[    1.620306] usb 1-6: Product: EasyCamera
[    1.620309] usb 1-6: Manufacturer: Chicony Electronics Co.,Ltd.
[    1.620312] usb 1-6: SerialNumber: 0001
[    1.711773] systemd[1]: bpf-lsm: LSM BPF program attached
[    1.783983] systemd[1]: Queued start job for default target initrd.target.
[    1.784296] systemd[1]: Reached target initrd-usr-fs.target - Initrd /usr File System.
[    1.784403] systemd[1]: Reached target local-fs.target - Local File Systems.
[    1.784447] systemd[1]: Reached target slices.target - Slice Units.
[    1.784486] systemd[1]: Reached target swap.target - Swaps.
[    1.784522] systemd[1]: Reached target timers.target - Timer Units.
[    1.784669] systemd[1]: Listening on dbus.socket - D-Bus System Message Bus Socket.
[    1.784885] systemd[1]: Listening on systemd-journald-audit.socket - Journal Audit Socket.
[    1.785041] systemd[1]: Listening on systemd-journald-dev-log.socket - Journal Socket (/dev/log).
[    1.785234] systemd[1]: Listening on systemd-journald.socket - Journal Socket.
[    1.785401] systemd[1]: Listening on systemd-udevd-control.socket - udev Control Socket.
[    1.785527] systemd[1]: Listening on systemd-udevd-kernel.socket - udev Kernel Socket.
[    1.785568] systemd[1]: Reached target sockets.target - Socket Units.
[    1.787720] systemd[1]: Starting kmod-static-nodes.service - Create List of Static Device Nodes...
[    1.787819] systemd[1]: memstrack.service - Memstrack Anylazing Service was skipped because all trigger condition checks failed.
[    1.790078] systemd[1]: Starting systemd-journald.service - Journal Service...
[    1.791917] systemd[1]: Starting systemd-modules-load.service - Load Kernel Modules...
[    1.793473] systemd[1]: Starting systemd-sysusers.service - Create System Users...
[    1.795269] systemd[1]: Starting systemd-vconsole-setup.service - Setup Virtual Console...
[    1.805694] systemd[1]: Finished kmod-static-nodes.service - Create List of Static Device Nodes.
[    1.823804] systemd[1]: Finished systemd-sysusers.service - Create System Users.
[    1.825650] audit: type=1130 audit(1667836737.370:2): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-sysusers comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.825873] systemd[1]: Starting systemd-tmpfiles-setup-dev.service - Create Static Device Nodes in /dev...
[    1.841577] systemd[1]: Finished systemd-tmpfiles-setup-dev.service - Create Static Device Nodes in /dev.
[    1.841877] audit: type=1130 audit(1667836737.388:3): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-tmpfiles-setup-dev comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.876057] fuse: init (API version 7.36)
[    1.884837] systemd[1]: Started systemd-journald.service - Journal Service.
[    1.887207] audit: type=1130 audit(1667836737.431:4): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-journald comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.899741] audit: type=1130 audit(1667836737.446:5): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-modules-load comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.908594] audit: type=1130 audit(1667836737.455:6): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-vconsole-setup comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.916637] audit: type=1130 audit(1667836737.463:7): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-tmpfiles-setup comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.936777] audit: type=1130 audit(1667836737.483:8): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-sysctl comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    1.991573] audit: type=1130 audit(1667836737.538:9): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=dracut-cmdline comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    2.027583] audit: type=1130 audit(1667836737.574:10): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=dracut-pre-udev comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    2.289116] ACPI: video: Video Device [VGA] (multi-head: yes  rom: no  post: no)
[    2.290028] acpi device:0c: registered as cooling_device4
[    2.290126] input: Video Bus as /devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:0b/LNXVIDEO:00/input/input4
[    2.322237] sp5100_tco: SP5100/SB800 TCO WatchDog Timer Driver
[    2.322450] sp5100-tco sp5100-tco: Using 0xfeb00000 for watchdog MMIO address
[    2.322587] sp5100-tco sp5100-tco: initialized. heartbeat=60 sec (nowayout=0)
[    2.328148] acpi PNP0C14:01: duplicate WMI GUID 05901221-D566-11D1-B2F0-00A0C9062910 (first instance was on PNP0C14:00)
[    2.328852] acpi PNP0C14:02: duplicate WMI GUID 05901221-D566-11D1-B2F0-00A0C9062910 (first instance was on PNP0C14:00)
[    2.350780] pcie_mp2_amd 0000:03:00.7: enabling device (0000 -> 0002)
[    2.350866] ccp 0000:03:00.2: enabling device (0000 -> 0002)
[    2.353337] ccp 0000:03:00.2: ccp enabled
[    2.364139] sdhci: Secure Digital Host Controller Interface driver
[    2.364146] sdhci: Copyright(c) Pierre Ossman
[    2.370253] ccp 0000:03:00.2: tee enabled
[    2.370263] ccp 0000:03:00.2: psp enabled
[    2.411471] mmc0: SDHCI controller on ACPI [AMDI0041:00] using ADMA
[    2.543148] input: ELAN238E:00 04F3:2894 Touchscreen as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input5
[    2.543350] input: ELAN238E:00 04F3:2894 as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input6
[    2.543436] input: ELAN238E:00 04F3:2894 as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input7
[    2.543534] input: ELAN238E:00 04F3:2894 Stylus as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input8
[    2.543743] hid-generic 0018:04F3:2894.0001: input,hidraw0: I2C HID v1.00 Device [ELAN238E:00 04F3:2894] on i2c-ELAN238E:00
[    2.567329] sdhci-pci 0000:02:00.0: SDHCI controller found [1217:8621] (rev 1)
[    2.567431] sdhci-pci 0000:02:00.0: enabling device (0000 -> 0002)
[    2.568273] mmc1: SDHCI controller on PCI [0000:02:00.0] using ADMA
[    2.580880] AMD-Vi: AMD IOMMUv2 loaded and initialized
[    2.591573] mmc0: new HS400 MMC card at address 0001
[    2.597395] input: ELAN238E:00 04F3:2894 as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input11
[    2.597588] input: ELAN238E:00 04F3:2894 UNKNOWN as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input12
[    2.597685] input: ELAN238E:00 04F3:2894 UNKNOWN as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input13
[    2.597811] input: ELAN238E:00 04F3:2894 Stylus as /devices/platform/AMDI0010:00/i2c-0/i2c-ELAN238E:00/0018:04F3:2894.0001/input/input14
[    2.598438] hid-multitouch 0018:04F3:2894.0001: input,hidraw0: I2C HID v1.00 Device [ELAN238E:00 04F3:2894] on i2c-ELAN238E:00
[    2.607360] mmcblk0: mmc0:0001 MMC64G 58.2 GiB 
[    2.611381]  mmcblk0: p1 p2 p3 p4 p5 p6
[    2.616777] mmcblk0boot0: mmc0:0001 MMC64G 4.00 MiB 
[    2.617994] mmcblk0boot1: mmc0:0001 MMC64G 4.00 MiB 
[    2.618877] mmcblk0rpmb: mmc0:0001 MMC64G 4.00 MiB, chardev (236:0)
[    2.630506] typec port0: bound usb1-port1 (ops connector_ops)
[    2.630530] typec port0: bound usb2-port1 (ops connector_ops)
[    4.871321] [drm] amdgpu kernel modesetting enabled.
[    4.876240] amdgpu: Topology: Add APU node [0x0:0x0]
[    4.891818] amdgpu 0000:03:00.0: vgaarb: deactivate vga console
[    4.891917] amdgpu 0000:03:00.0: enabling device (0006 -> 0007)
[    4.892049] [drm] initializing kernel modesetting (RAVEN 0x1002:0x15D8 0x17AA:0x380C 0xE9).
[    4.892448] [drm] register mmio base: 0xFC600000
[    4.892454] [drm] register mmio size: 524288
[    4.892573] [drm] add ip block number 0 <soc15_common>
[    4.892579] [drm] add ip block number 1 <gmc_v9_0>
[    4.892582] [drm] add ip block number 2 <vega10_ih>
[    4.892586] [drm] add ip block number 3 <psp>
[    4.892588] [drm] add ip block number 4 <powerplay>
[    4.892591] [drm] add ip block number 5 <dm>
[    4.892594] [drm] add ip block number 6 <gfx_v9_0>
[    4.892597] [drm] add ip block number 7 <sdma_v4_0>
[    4.892600] [drm] add ip block number 8 <vcn_v1_0>
[    4.893481] amdgpu 0000:03:00.0: amdgpu: Fetched VBIOS from VFCT
[    4.893489] amdgpu: ATOM BIOS: 113-RAVEN2-117
[    4.895441] [drm] VCN decode is enabled in VM mode
[    4.895445] [drm] VCN encode is enabled in VM mode
[    4.895446] [drm] JPEG decode is enabled in VM mode
[    4.895449] amdgpu 0000:03:00.0: amdgpu: Trusted Memory Zone (TMZ) feature enabled
[    4.895507] [drm] vm size is 262144 GB, 3 levels, block size is 9-bit, fragment size is 9-bit
[    4.895519] amdgpu 0000:03:00.0: amdgpu: VRAM: 512M 0x000000F400000000 - 0x000000F41FFFFFFF (512M used)
[    4.895525] amdgpu 0000:03:00.0: amdgpu: GART: 1024M 0x0000000000000000 - 0x000000003FFFFFFF
[    4.895528] amdgpu 0000:03:00.0: amdgpu: AGP: 267419648M 0x000000F800000000 - 0x0000FFFFFFFFFFFF
[    4.895540] [drm] Detected VRAM RAM=512M, BAR=512M
[    4.895543] [drm] RAM width 64bits DDR4
[    4.895619] [drm] amdgpu: 512M of VRAM memory ready
[    4.895623] [drm] amdgpu: 3072M of GTT memory ready.
[    4.895641] [drm] GART: num cpu pages 262144, num gpu pages 262144
[    4.895921] [drm] PCIE GART of 1024M enabled.
[    4.895923] [drm] PTB located at 0x000000F400900000
[    4.906793] amdgpu 0000:03:00.0: amdgpu: PSP runtime database doesn't exist
[    4.906801] amdgpu 0000:03:00.0: amdgpu: PSP runtime database doesn't exist
[    4.906865] amdgpu: hwmgr_sw_init smu backed is smu10_smu
[    4.959045] [drm] Found VCN firmware Version ENC: 1.13 DEC: 2 VEP: 0 Revision: 3
[    4.959060] amdgpu 0000:03:00.0: amdgpu: Will use PSP to load VCN firmware
[    4.980455] [drm] reserve 0x400000 from 0xf41fc00000 for PSP TMR
[    5.025015] [drm] failed to load ucode RLC_RESTORE_LIST_CNTL(0x23) 
[    5.025019] [drm] psp gfx command LOAD_IP_FW(0x6) failed and response status is (0xFFFF300F)
[    5.025540] [drm] failed to load ucode RLC_RESTORE_LIST_GPM_MEM(0x24) 
[    5.025543] [drm] psp gfx command LOAD_IP_FW(0x6) failed and response status is (0xFFFF000F)
[    5.026121] [drm] failed to load ucode RLC_RESTORE_LIST_SRM_MEM(0x25) 
[    5.026123] [drm] psp gfx command LOAD_IP_FW(0x6) failed and response status is (0xFFFF000F)
[    5.056542] amdgpu 0000:03:00.0: amdgpu: RAS: optional ras ta ucode is not available
[    5.066768] amdgpu 0000:03:00.0: amdgpu: RAP: optional rap ta ucode is not available
[    5.066770] amdgpu 0000:03:00.0: amdgpu: SECUREDISPLAY: securedisplay ta ucode is not available
[    5.067319] [drm] DM_PPLIB: values for F clock
[    5.067322] [drm] DM_PPLIB:	 400000 in kHz, 3174 in mV
[    5.067324] [drm] DM_PPLIB:	 800000 in kHz, 3724 in mV
[    5.067326] [drm] DM_PPLIB: values for DCF clock
[    5.067327] [drm] DM_PPLIB:	 300000 in kHz, 3174 in mV
[    5.067329] [drm] DM_PPLIB:	 600000 in kHz, 3724 in mV
[    5.067330] [drm] DM_PPLIB:	 626000 in kHz, 3924 in mV
[    5.067331] [drm] DM_PPLIB:	 654000 in kHz, 4074 in mV
[    5.067674] [drm] Display Core initialized with v3.2.187!
[    5.162425] [drm] kiq ring mec 2 pipe 1 q 0
[    5.177252] [drm] VCN decode and encode initialized successfully(under SPG Mode).
[    5.179504] kfd kfd: amdgpu: Allocated 3969056 bytes on gart
[    5.179584] amdgpu: sdma_bitmap: 3
[    5.196365] memmap_init_zone_device initialised 131072 pages in 3ms
[    5.196385] amdgpu: HMM registered 512MB device memory
[    5.196510] amdgpu: Topology: Add APU node [0x15d8:0x1002]
[    5.196517] kfd kfd: amdgpu: added device 1002:15d8
[    5.196651] amdgpu 0000:03:00.0: amdgpu: SE 1, SH per SE 1, CU per SH 3, active_cu_number 3
[    5.196828] amdgpu 0000:03:00.0: amdgpu: ring gfx uses VM inv eng 0 on hub 0
[    5.196831] amdgpu 0000:03:00.0: amdgpu: ring comp_1.0.0 uses VM inv eng 1 on hub 0
[    5.196834] amdgpu 0000:03:00.0: amdgpu: ring comp_1.1.0 uses VM inv eng 4 on hub 0
[    5.196836] amdgpu 0000:03:00.0: amdgpu: ring comp_1.2.0 uses VM inv eng 5 on hub 0
[    5.196838] amdgpu 0000:03:00.0: amdgpu: ring comp_1.3.0 uses VM inv eng 6 on hub 0
[    5.196840] amdgpu 0000:03:00.0: amdgpu: ring comp_1.0.1 uses VM inv eng 7 on hub 0
[    5.196842] amdgpu 0000:03:00.0: amdgpu: ring comp_1.1.1 uses VM inv eng 8 on hub 0
[    5.196844] amdgpu 0000:03:00.0: amdgpu: ring comp_1.2.1 uses VM inv eng 9 on hub 0
[    5.196846] amdgpu 0000:03:00.0: amdgpu: ring comp_1.3.1 uses VM inv eng 10 on hub 0
[    5.196848] amdgpu 0000:03:00.0: amdgpu: ring kiq_2.1.0 uses VM inv eng 11 on hub 0
[    5.196850] amdgpu 0000:03:00.0: amdgpu: ring sdma0 uses VM inv eng 0 on hub 1
[    5.196851] amdgpu 0000:03:00.0: amdgpu: ring vcn_dec uses VM inv eng 1 on hub 1
[    5.196853] amdgpu 0000:03:00.0: amdgpu: ring vcn_enc0 uses VM inv eng 4 on hub 1
[    5.196855] amdgpu 0000:03:00.0: amdgpu: ring vcn_enc1 uses VM inv eng 5 on hub 1
[    5.196857] amdgpu 0000:03:00.0: amdgpu: ring jpeg_dec uses VM inv eng 6 on hub 1
[    5.203158] [drm] Initialized amdgpu 3.47.0 20150101 for 0000:03:00.0 on minor 0
[    5.213677] fbcon: amdgpudrmfb (fb0) is primary device
[    5.213685] fbcon: Deferring console take-over
[    5.213691] amdgpu 0000:03:00.0: [drm] fb0: amdgpudrmfb frame buffer device
[    5.260751] kauditd_printk_skb: 6 callbacks suppressed
[    5.260758] audit: type=1130 audit(1667836740.807:17): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=dracut-initqueue comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    5.299961] audit: type=1130 audit(1667836740.846:18): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=kernel msg='unit=systemd-fsck-root comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
[    5.312824] EXT4-fs (mmcblk0p6): mounted filesystem with ordered data mode. Quota mode: none.
[    5.486561] audit: type=1334 audit(1667836741.033:19): prog-id=26 op=LOAD
[    5.486573] audit: type=1334 audit(1667836741.033:20): prog-id=0 op=UNLOAD
[    5.486718] audit: type=1334 audit(1667836741.033:21): prog-id=27 op=LOAD
[    5.486773] audit: type=1334 audit(1667836741.033:22): prog-id=28 op=LOAD
[    5.486802] audit: type=1334 audit(1667836741.033:23): prog-id=0 op=UNLOAD
[    5.486816] audit: type=1334 audit(1667836741.033:24): prog-id=0 op=UNLOAD
[    5.488305] audit: type=1334 audit(1667836741.035:25): prog-id=29 op=LOAD
[    5.488312] audit: type=1334 audit(1667836741.035:26): prog-id=0 op=UNLOAD
[    5.849236] systemd-journald[247]: Received SIGTERM from PID 1 (systemd).
[    6.074809] SELinux:  policy capability network_peer_controls=1
[    6.074818] SELinux:  policy capability open_perms=1
[    6.074820] SELinux:  policy capability extended_socket_class=1
[    6.074821] SELinux:  policy capability always_check_network=0
[    6.074823] SELinux:  policy capability cgroup_seclabel=1
[    6.074824] SELinux:  policy capability nnp_nosuid_transition=1
[    6.074825] SELinux:  policy capability genfs_seclabel_symlinks=1
[    6.074826] SELinux:  policy capability ioctl_skip_cloexec=0
[    6.137340] systemd[1]: Successfully loaded SELinux policy in 126.683ms.
[    6.155433] systemd[1]: RTC configured in localtime, applying delta of -300 minutes to system time.
[    6.210343] systemd[1]: Relabelled /dev, /dev/shm, /run, /sys/fs/cgroup in 47.922ms.
[    6.221837] systemd[1]: systemd 251.4-53.fc37 running in system mode (+PAM +AUDIT +SELINUX -APPARMOR +IMA +SMACK +SECCOMP -GCRYPT +GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN -IPTC +KMOD +LIBCRYPTSETUP +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +XKBCOMMON +UTMP +SYSVINIT default-hierarchy=unified)
[    6.221850] systemd[1]: Detected architecture x86-64.
[    6.559372] systemd[1]: bpf-lsm: LSM BPF program attached
[    6.784619] systemd-sysv-generator[528]: SysV service '/etc/rc.d/init.d/livesys-late' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    6.787597] systemd-sysv-generator[528]: SysV service '/etc/rc.d/init.d/livesys' lacks a native systemd unit file. Automatically generating a unit file for compatibility. Please update package to include a native systemd unit file, in order to make it more safe and robust.
[    7.013728] systemd-gpt-auto-generator[522]: Failed to dissect: Permission denied
[    7.031313] zram: Added device: zram0
[    7.032165] systemd[508]: /usr/lib/systemd/system-generators/systemd-gpt-auto-generator failed with exit status 1.
[    7.326419] systemd[1]: initrd-switch-root.service: Deactivated successfully.
[    7.336421] systemd[1]: Stopped initrd-switch-root.service - Switch Root.
[    7.337508] systemd[1]: systemd-journald.service: Scheduled restart job, restart counter is at 1.
[    7.338317] systemd[1]: Created slice machine.slice - Virtual Machine and Container Slice.
[    7.339200] systemd[1]: Created slice system-getty.slice - Slice /system/getty.
[    7.339867] systemd[1]: Created slice system-modprobe.slice - Slice /system/modprobe.
[    7.340536] systemd[1]: Created slice system-sshd\x2dkeygen.slice - Slice /system/sshd-keygen.
[    7.341267] systemd[1]: Created slice system-systemd\x2dfsck.slice - Slice /system/systemd-fsck.
[    7.341907] systemd[1]: Created slice system-systemd\x2dzram\x2dsetup.slice - Slice /system/systemd-zram-setup.
[    7.342599] systemd[1]: Created slice user.slice - User and Session Slice.
[    7.342675] systemd[1]: systemd-ask-password-console.path - Dispatch Password Requests to Console Directory Watch was skipped because of a failed condition check (ConditionPathExists=!/run/plymouth/pid).
[    7.342967] systemd[1]: Started systemd-ask-password-wall.path - Forward Password Requests to Wall Directory Watch.
[    7.343801] systemd[1]: Set up automount proc-sys-fs-binfmt_misc.automount - Arbitrary Executable File Formats File System Automount Point.
[    7.343933] systemd[1]: Reached target cryptsetup.target - Local Encrypted Volumes.
[    7.344005] systemd[1]: Reached target getty.target - Login Prompts.
[    7.344076] systemd[1]: Stopped target initrd-switch-root.target - Switch Root.
[    7.344145] systemd[1]: Stopped target initrd-fs.target - Initrd File Systems.
[    7.344290] systemd[1]: Stopped target initrd-root-fs.target - Initrd Root File System.
[    7.344381] systemd[1]: Reached target integritysetup.target - Local Integrity Protected Volumes.
[    7.344548] systemd[1]: Reached target slices.target - Slice Units.
[    7.344654] systemd[1]: Reached target veritysetup.target - Local Verity Protected Volumes.
[    7.345517] systemd[1]: Listening on dm-event.socket - Device-mapper event daemon FIFOs.
[    7.347424] systemd[1]: Listening on lvm2-lvmpolld.socket - LVM2 poll daemon socket.
[    7.350027] systemd[1]: Listening on systemd-coredump.socket - Process Core Dump Socket.
[    7.350362] systemd[1]: Listening on systemd-initctl.socket - initctl Compatibility Named Pipe.
[    7.351269] systemd[1]: Listening on systemd-oomd.socket - Userspace Out-Of-Memory (OOM) Killer Socket.
[    7.353336] systemd[1]: Listening on systemd-udevd-control.socket - udev Control Socket.
[    7.354140] systemd[1]: Listening on systemd-udevd-kernel.socket - udev Kernel Socket.
[    7.354873] systemd[1]: Listening on systemd-userdbd.socket - User Database Manager Socket.
[    7.357841] systemd[1]: Mounting dev-hugepages.mount - Huge Pages File System...
[    7.360655] systemd[1]: Mounting dev-mqueue.mount - POSIX Message Queue File System...
[    7.363680] systemd[1]: Mounting sys-kernel-debug.mount - Kernel Debug File System...
[    7.366313] systemd[1]: Mounting sys-kernel-tracing.mount - Kernel Trace File System...
[    7.366793] systemd[1]: auth-rpcgss-module.service - Kernel Module supporting RPCSEC_GSS was skipped because of a failed condition check (ConditionPathExists=/etc/krb5.keytab).
[    7.370100] systemd[1]: Starting kmod-static-nodes.service - Create List of Static Device Nodes...
[    7.373286] systemd[1]: Starting lvm2-monitor.service - Monitoring of LVM2 mirrors, snapshots etc. using dmeventd or progress polling...
[    7.376158] systemd[1]: Starting modprobe@configfs.service - Load Kernel Module configfs...
[    7.379722] systemd[1]: Starting modprobe@drm.service - Load Kernel Module drm...
[    7.383253] systemd[1]: Starting modprobe@fuse.service - Load Kernel Module fuse...
[    7.386810] systemd[1]: Starting nfs-convert.service - Preprocess NFS configuration convertion...
[    7.387098] systemd[1]: plymouth-switch-root.service: Deactivated successfully.
[    7.392405] systemd[1]: Stopped plymouth-switch-root.service - Plymouth switch root service.
[    7.393001] systemd[1]: Stopped systemd-journald.service - Journal Service.
[    7.397384] systemd[1]: Starting systemd-journald.service - Journal Service...
[    7.401700] systemd[1]: Starting systemd-modules-load.service - Load Kernel Modules...
[    7.405008] systemd[1]: Starting systemd-network-generator.service - Generate network units from Kernel command line...
[    7.408097] systemd[1]: Starting systemd-remount-fs.service - Remount Root and Kernel File Systems...
[    7.408365] systemd[1]: systemd-repart.service - Repartition Root Disk was skipped because all trigger condition checks failed.
[    7.411382] systemd[1]: Starting systemd-udev-trigger.service - Coldplug All udev Devices...
[    7.415517] systemd[1]: Mounted dev-hugepages.mount - Huge Pages File System.
[    7.415948] systemd[1]: Mounted dev-mqueue.mount - POSIX Message Queue File System.
[    7.416269] systemd[1]: Mounted sys-kernel-debug.mount - Kernel Debug File System.
[    7.416575] systemd[1]: Mounted sys-kernel-tracing.mount - Kernel Trace File System.
[    7.430474] systemd[1]: Finished kmod-static-nodes.service - Create List of Static Device Nodes.
[    7.431119] systemd[1]: modprobe@configfs.service: Deactivated successfully.
[    7.440544] systemd[1]: Finished modprobe@configfs.service - Load Kernel Module configfs.
[    7.441094] systemd[1]: modprobe@drm.service: Deactivated successfully.
[    7.454456] systemd[1]: Finished modprobe@drm.service - Load Kernel Module drm.
[    7.454963] systemd[1]: modprobe@fuse.service: Deactivated successfully.
[    7.464430] systemd[1]: Finished modprobe@fuse.service - Load Kernel Module fuse.
[    7.465501] systemd[1]: nfs-convert.service: Deactivated successfully.
[    7.473536] systemd[1]: Finished nfs-convert.service - Preprocess NFS configuration convertion.
[    7.477469] systemd[1]: Mounting sys-fs-fuse-connections.mount - FUSE Control File System...
[    7.480069] systemd[1]: Mounting sys-kernel-config.mount - Kernel Configuration File System...
[    7.481672] systemd[1]: Mounted sys-fs-fuse-connections.mount - FUSE Control File System.
[    7.483545] systemd[1]: Mounted sys-kernel-config.mount - Kernel Configuration File System.
[    7.522795] EXT4-fs (mmcblk0p6): re-mounted. Quota mode: none.
[    7.524639] systemd[1]: Finished systemd-network-generator.service - Generate network units from Kernel command line.
[    7.538618] systemd[1]: Finished systemd-remount-fs.service - Remount Root and Kernel File Systems.
[    7.539467] systemd[1]: Started systemd-journald.service - Journal Service.
[    7.566386] systemd-journald[550]: Received client request to flush runtime journal.
[    7.957005] zram0: detected capacity change from 0 to 6746112
[    8.087991] Adding 3373052k swap on /dev/zram0.  Priority:100 extents:1 across:3373052k SSDscFS
[    8.128437] acpi_cpufreq: overriding BIOS provided _PSD data
[    8.331812] piix4_smbus 0000:00:14.0: SMBus Host Controller at 0xb00, revision 0
[    8.331824] piix4_smbus 0000:00:14.0: Using register 0x02 for SMBus port selection
[    8.332068] piix4_smbus 0000:00:14.0: Auxiliary SMBus Host Controller at 0xb20
[    8.502753] input: PC Speaker as /devices/platform/pcspkr/input/input17
[    8.505943] snd_pci_acp3x 0000:03:00.5: enabling device (0000 -> 0002)
[    8.506159] snd_pci_acp3x 0000:03:00.5: ACP audio mode : 1
[    8.623303] RAPL PMU: API unit is 2^-32 Joules, 1 fixed counters, 163840 ms ovfl timer
[    8.623312] RAPL PMU: hw unit of domain package 2^-16 Joules
[    8.623726] input: Ideapad extra buttons as /devices/pci0000:00/0000:00:14.3/PNP0C09:00/VPC2004:00/input/input18
[    8.624130] ideapad_acpi VPC2004:00: Keyboard backlight control not available
[    8.786873] ideapad_acpi VPC2004:00: DYTC interface is not available
[    8.857704] mc: Linux media interface: v0.10
[    8.975989] cfg80211: Loading compiled-in X.509 certificates for regulatory database
[    8.977625] cfg80211: Loaded X.509 cert 'sforshee: 00b28ddf47aef9cea7'
[    8.984896] SVM: TSC scaling supported
[    8.984905] kvm: Nested Virtualization enabled
[    8.984908] SVM: kvm: Nested Paging enabled
[    8.984913] SEV supported: 16 ASIDs
[    8.984916] SEV-ES supported: 4294967295 ASIDs
[    8.984950] SVM: Virtual VMLOAD VMSAVE supported
[    8.984951] SVM: Virtual GIF supported
[    8.984952] SVM: LBR virtualization supported
[    9.044589] Bluetooth: Core ver 2.22
[    9.044726] NET: Registered PF_BLUETOOTH protocol family
[    9.044730] Bluetooth: HCI device and connection manager initialized
[    9.044742] Bluetooth: HCI socket layer initialized
[    9.044752] Bluetooth: L2CAP socket layer initialized
[    9.044766] Bluetooth: SCO socket layer initialized
[    9.058533] videodev: Linux video capture interface: v2.00
[    9.063345] MCE: In-kernel MCE decoding enabled.
[    9.094065] EXT4-fs (mmcblk0p5): mounted filesystem with ordered data mode. Quota mode: none.
[    9.132243] intel_rapl_common: Found RAPL domain package
[    9.132252] intel_rapl_common: Found RAPL domain core
[    9.250485] usbcore: registered new interface driver btusb
[    9.261922] Bluetooth: hci0: HCI Read Default Erroneous Data Reporting command is advertised, but not supported.
[    9.261933] Bluetooth: hci0: HCI Enhanced Setup Synchronous Connection command is advertised, but not supported.
[    9.340243] snd_hda_intel 0000:03:00.1: enabling device (0000 -> 0002)
[    9.340382] snd_hda_intel 0000:03:00.1: Handle vga_switcheroo audio client
[    9.346732] snd_hda_intel 0000:03:00.6: enabling device (0000 -> 0002)
[    9.376173] snd_hda_intel 0000:03:00.1: bound 0000:03:00.0 (ops amdgpu_dm_audio_component_bind_ops [amdgpu])
[    9.379482] input: HD-Audio Generic HDMI/DP,pcm=3 as /devices/pci0000:00/0000:00:08.1/0000:03:00.1/sound/card0/input19
[    9.381433] input: HD-Audio Generic HDMI/DP,pcm=7 as /devices/pci0000:00/0000:00:08.1/0000:03:00.1/sound/card0/input20
[    9.381604] input: HD-Audio Generic HDMI/DP,pcm=8 as /devices/pci0000:00/0000:00:08.1/0000:03:00.1/sound/card0/input21
[    9.381826] input: HD-Audio Generic HDMI/DP,pcm=9 as /devices/pci0000:00/0000:00:08.1/0000:03:00.1/sound/card0/input22
[    9.449953] usb 1-6: Found UVC 1.00 device EasyCamera (04f2:b6d3)
[    9.463877] input: EasyCamera: EasyCamera as /devices/pci0000:00/0000:00:08.1/0000:03:00.3/usb1/1-6/1-6:1.0/input/input23
[    9.464031] usbcore: registered new interface driver uvcvideo
[    9.479737] snd_hda_codec_realtek hdaudioC1D0: autoconfig for ALC257: line_outs=1 (0x14/0x0/0x0/0x0/0x0) type:speaker
[    9.479751] snd_hda_codec_realtek hdaudioC1D0:    speaker_outs=0 (0x0/0x0/0x0/0x0/0x0)
[    9.479755] snd_hda_codec_realtek hdaudioC1D0:    hp_outs=1 (0x21/0x0/0x0/0x0/0x0)
[    9.479760] snd_hda_codec_realtek hdaudioC1D0:    mono: mono_out=0x0
[    9.479762] snd_hda_codec_realtek hdaudioC1D0:    inputs:
[    9.479765] snd_hda_codec_realtek hdaudioC1D0:      Mic=0x19
[    9.479768] snd_hda_codec_realtek hdaudioC1D0:      Internal Mic=0x13
[    9.522095] ath10k_pci 0000:01:00.0: enabling device (0000 -> 0002)
[    9.524937] ath10k_pci 0000:01:00.0: pci irq msi oper_irq_mode 2 irq_mode 0 reset_mode 0
[    9.525259] input: HD-Audio Generic Mic as /devices/pci0000:00/0000:00:08.1/0000:03:00.6/sound/card1/input24
[    9.526097] input: HD-Audio Generic Headphone as /devices/pci0000:00/0000:00:08.1/0000:03:00.6/sound/card1/input25
[    9.825762] ath10k_pci 0000:01:00.0: qca6174 hw3.2 target 0x05030000 chip_id 0x00340aff sub 17aa:0827
[    9.825777] ath10k_pci 0000:01:00.0: kconfig debug 0 debugfs 1 tracing 0 dfs 0 testmode 0
[    9.826652] ath10k_pci 0000:01:00.0: firmware ver WLAN.RM.4.4.1-00288- api 6 features wowlan,ignore-otp,mfp crc32 bf907c7c
[    9.873801] RPC: Registered named UNIX socket transport module.
[    9.873809] RPC: Registered udp transport module.
[    9.873812] RPC: Registered tcp transport module.
[    9.873814] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    9.906789] ath10k_pci 0000:01:00.0: board_file api 2 bmi_id N/A crc32 62812cba
[   10.001859] ath10k_pci 0000:01:00.0: htt-ver 3.87 wmi-op 4 htt-op 3 cal otp max-sta 32 raw 0 hwcrypto 1
[   10.063519] ath: EEPROM regdomain: 0x6c
[   10.063527] ath: EEPROM indicates we should expect a direct regpair map
[   10.063529] ath: Country alpha2 being used: 00
[   10.063532] ath: Regpair used: 0x6c
[   10.148205] ath10k_pci 0000:01:00.0 wlp1s0: renamed from wlan0
[   10.480786] Bluetooth: BNEP (Ethernet Emulation) ver 1.3
[   10.480794] Bluetooth: BNEP filters: protocol multicast
[   10.480802] Bluetooth: BNEP socket layer initialized
[   10.888914] NET: Registered PF_QIPCRTR protocol family
[   17.035281] wlp1s0: authenticate with 94:83:c4:13:b7:8b
[   17.084318] wlp1s0: send auth to 94:83:c4:13:b7:8b (try 1/3)
[   17.094028] wlp1s0: authenticated
[   17.096295] wlp1s0: associate with 94:83:c4:13:b7:8b (try 1/3)
[   17.099657] wlp1s0: RX AssocResp from 94:83:c4:13:b7:8b (capab=0x11 status=0 aid=5)
[   17.104750] wlp1s0: associated
[   17.105339] ath: EEPROM regdomain: 0x8114
[   17.105360] ath: EEPROM indicates we should expect a country code
[   17.105371] ath: doing EEPROM country->regdmn map search
[   17.105379] ath: country maps to regdmn code: 0x37
[   17.105389] ath: Country alpha2 being used: DE
[   17.105398] ath: Regpair used: 0x37
[   17.105407] ath: regdomain 0x8114 dynamically updated by country element
[   17.218327] IPv6: ADDRCONF(NETDEV_CHANGE): wlp1s0: link becomes ready
[   22.659338] rfkill: input handler disabled
[   22.802188] Bluetooth: RFCOMM TTY layer initialized
[   22.802188] Bluetooth: RFCOMM socket layer initialized
[   22.802387] Bluetooth: RFCOMM ver 1.11
[steve@fedora ~]$ 
```
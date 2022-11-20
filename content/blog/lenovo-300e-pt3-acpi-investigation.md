---
title: "Lenovo 300e Gen 2, Part 3: Digging in to the Laptop/slate switch and ACPI"
date: 2022-11-20T10:00:00+02:00
---

# Recap

Last time, [we determined that simply asking Linux to identify as Windows didn't make a difference]({{< relref "lenovo-300e-pt2-lshw-lspci-dmesg-acpi"  >}}). That's okay, it was a long shot anyway. However, we also gathered a bunch of useful general information about the system.

Now we'll get started with specific tasks to determine why the laptop/slate mode switch doesn't work.

# Identifiers Recap

We got the following [identifiers out of Windows in part 1]({{< relref "lenovo-300e-gen2-linux#collecting-identifiers" >}}):

* BIOS Name: `\_SB.CIND`
* Compatible IDs: `ACPI\PNP0C60` and `PNP0C60`
* Hardware IDs: `ACPI\VEN_AMDI&DEV_0081`, `ACPI\AMDI0081`, `*AMDI0081`
* Device Instance Path: `ACPI\AMDI0081\0`

From these identifiers, we know the Laptop/slate mode switch is an ACPI device - mostly from `Device Instance Path`, but also because `ACPI` appears in a bunch of places in identifiers.

In part 2, we gathered [the full `dmesg` output]({{< relref "lenovo-300e-pt2-lshw-lspci-dmesg-acpi#dmesg-output" >}}). That's rather long, so let's find all the `dmesg` output that mentions ACPI:

```shell
[steve@fedora ~]$ sudo dmesg | grep -i acpi
[sudo] password for steve: 
[    0.000000] BIOS-e820: [mem 0x0000000009f00000-0x0000000009f0afff] ACPI NVS
[    0.000000] BIOS-e820: [mem 0x00000000cc57e000-0x00000000ce57dfff] ACPI NVS
[    0.000000] BIOS-e820: [mem 0x00000000ce57e000-0x00000000ce5fdfff] ACPI data
[    0.000000] reserve setup_data: [mem 0x0000000009f00000-0x0000000009f0afff] ACPI NVS
[    0.000000] reserve setup_data: [mem 0x00000000cc57e000-0x00000000ce57dfff] ACPI NVS
[    0.000000] reserve setup_data: [mem 0x00000000ce57e000-0x00000000ce5fdfff] ACPI data
[    0.000000] efi: ACPI=0xce5fd000 ACPI 2.0=0xce5fd014 TPMFinalLog=0xce42e000 SMBIOS=0xca45d000 SMBIOS 3.0=0xca450000 MEMATTR=0xc563b018 ESRT=0xc91b6000 MOKvar=0xc91bd000 TPMEventLog=0xad4a0018 
[    0.008498] ACPI: Early table checksum verification disabled
[    0.008505] ACPI: RSDP 0x00000000CE5FD014 000024 (v02 LENOVO)
[    0.008513] ACPI: XSDT 0x00000000CE5FB188 0000EC (v01 LENOVO CB-01    00000003 PTEC 00000002)
[    0.008522] ACPI: FACP 0x00000000C91E3000 00010C (v05 LENOVO CB-01    00000003 PTEC 00000002)
[    0.008531] ACPI: DSDT 0x00000000C91D4000 009154 (v01 LENOVO AMD      00001000 INTL 20180313)
[    0.008537] ACPI: FACS 0x00000000CDB7E000 000040
[    0.008541] ACPI: SSDT 0x00000000CA488000 000681 (v01 LENOVO UsbCUcsi 00000001 INTL 20180313)
[    0.008546] ACPI: SSDT 0x00000000CA482000 005419 (v02 LENOVO AmdTable 00000002 MSFT 02000002)
[    0.008551] ACPI: SSDT 0x00000000CA430000 000632 (v02 LENOVO Tpm2Tabl 00001000 INTL 20180313)
[    0.008556] ACPI: TPM2 0x00000000CA42F000 000034 (v03 LENOVO CB-01    00000002 PTEC 00000002)
[    0.008561] ACPI: MSDM 0x00000000CA40A000 000055 (v03 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008566] ACPI: BATB 0x00000000CA3E6000 00004A (v02 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008571] ACPI: HPET 0x00000000C91E2000 000038 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008575] ACPI: APIC 0x00000000C91E1000 000108 (v03 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008580] ACPI: MCFG 0x00000000C91E0000 00003C (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008585] ACPI: SBST 0x00000000C91DF000 000030 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008590] ACPI: WSMT 0x00000000C91DE000 000028 (v01 LENOVO CB-01    00000000 PTEC 00000002)
[    0.008594] ACPI: VFCT 0x00000000C91C6000 00D484 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008599] ACPI: IVRS 0x00000000C91C5000 00013E (v02 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008604] ACPI: SSDT 0x00000000C91C4000 0008E0 (v01 LENOVO AMD CPU  00000001 AMD  00000001)
[    0.008609] ACPI: CRAT 0x00000000C91C3000 000490 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008614] ACPI: CDIT 0x00000000C91C2000 000029 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008618] ACPI: FPDT 0x00000000C91C0000 000034 (v01 LENOVO CB-01    00000002 PTEC 00000002)
[    0.008623] ACPI: SSDT 0x00000000C91B9000 0013AE (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008628] ACPI: SSDT 0x00000000C91B7000 001556 (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008633] ACPI: SSDT 0x00000000C91B3000 002745 (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008637] ACPI: BGRT 0x00000000C91B2000 000038 (v01 LENOVO CB-01    00000002 PTEC 00000002)
[    0.008642] ACPI: UEFI 0x00000000CDB7D000 000116 (v01 LENOVO CB-01    00000001 PTEC 00000002)
[    0.008647] ACPI: SSDT 0x00000000C91BF000 00045F (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008652] ACPI: SSDT 0x00000000C91BE000 000743 (v01 LENOVO AmdTable 00000001 INTL 20180313)
[    0.008656] ACPI: Reserving FACP table memory at [mem 0xc91e3000-0xc91e310b]
[    0.008658] ACPI: Reserving DSDT table memory at [mem 0xc91d4000-0xc91dd153]
[    0.008660] ACPI: Reserving FACS table memory at [mem 0xcdb7e000-0xcdb7e03f]
[    0.008661] ACPI: Reserving SSDT table memory at [mem 0xca488000-0xca488680]
[    0.008663] ACPI: Reserving SSDT table memory at [mem 0xca482000-0xca487418]
[    0.008665] ACPI: Reserving SSDT table memory at [mem 0xca430000-0xca430631]
[    0.008666] ACPI: Reserving TPM2 table memory at [mem 0xca42f000-0xca42f033]
[    0.008668] ACPI: Reserving MSDM table memory at [mem 0xca40a000-0xca40a054]
[    0.008669] ACPI: Reserving BATB table memory at [mem 0xca3e6000-0xca3e6049]
[    0.008671] ACPI: Reserving HPET table memory at [mem 0xc91e2000-0xc91e2037]
[    0.008672] ACPI: Reserving APIC table memory at [mem 0xc91e1000-0xc91e1107]
[    0.008674] ACPI: Reserving MCFG table memory at [mem 0xc91e0000-0xc91e003b]
[    0.008675] ACPI: Reserving SBST table memory at [mem 0xc91df000-0xc91df02f]
[    0.008677] ACPI: Reserving WSMT table memory at [mem 0xc91de000-0xc91de027]
[    0.008678] ACPI: Reserving VFCT table memory at [mem 0xc91c6000-0xc91d3483]
[    0.008680] ACPI: Reserving IVRS table memory at [mem 0xc91c5000-0xc91c513d]
[    0.008681] ACPI: Reserving SSDT table memory at [mem 0xc91c4000-0xc91c48df]
[    0.008683] ACPI: Reserving CRAT table memory at [mem 0xc91c3000-0xc91c348f]
[    0.008684] ACPI: Reserving CDIT table memory at [mem 0xc91c2000-0xc91c2028]
[    0.008686] ACPI: Reserving FPDT table memory at [mem 0xc91c0000-0xc91c0033]
[    0.008688] ACPI: Reserving SSDT table memory at [mem 0xc91b9000-0xc91ba3ad]
[    0.008689] ACPI: Reserving SSDT table memory at [mem 0xc91b7000-0xc91b8555]
[    0.008691] ACPI: Reserving SSDT table memory at [mem 0xc91b3000-0xc91b5744]
[    0.008692] ACPI: Reserving BGRT table memory at [mem 0xc91b2000-0xc91b2037]
[    0.008694] ACPI: Reserving UEFI table memory at [mem 0xcdb7d000-0xcdb7d115]
[    0.008695] ACPI: Reserving SSDT table memory at [mem 0xc91bf000-0xc91bf45e]
[    0.008697] ACPI: Reserving SSDT table memory at [mem 0xc91be000-0xc91be742]
[    0.037175] ACPI: PM-Timer IO Port: 0x408
[    0.037190] ACPI: LAPIC_NMI (acpi_id[0x00] high edge lint[0x1])
[    0.037193] ACPI: LAPIC_NMI (acpi_id[0x01] high edge lint[0x1])
[    0.037195] ACPI: LAPIC_NMI (acpi_id[0x02] high edge lint[0x1])
[    0.037196] ACPI: LAPIC_NMI (acpi_id[0x03] high edge lint[0x1])
[    0.037198] ACPI: LAPIC_NMI (acpi_id[0x04] high edge lint[0x1])
[    0.037199] ACPI: LAPIC_NMI (acpi_id[0x05] high edge lint[0x1])
[    0.037200] ACPI: LAPIC_NMI (acpi_id[0x06] high edge lint[0x1])
[    0.037202] ACPI: LAPIC_NMI (acpi_id[0x07] high edge lint[0x1])
[    0.037236] ACPI: INT_SRC_OVR (bus 0 bus_irq 0 global_irq 2 dfl dfl)
[    0.037239] ACPI: INT_SRC_OVR (bus 0 bus_irq 9 global_irq 9 low level)
[    0.037245] ACPI: Using ACPI (MADT) for SMP configuration information
[    0.037247] ACPI: HPET id: 0x43538210 base: 0xfed00000
[    0.114317] ACPI: Core revision 20220331
[    0.245132] ACPI: PM: Registering ACPI NVS region [mem 0x09f00000-0x09f0afff] (45056 bytes)
[    0.245132] ACPI: PM: Registering ACPI NVS region [mem 0xcc57e000-0xce57dfff] (33554432 bytes)
[    0.246799] ACPI FADT declares the system doesn't support PCIe ASPM, so disable it
[    0.246799] acpiphp: ACPI Hot Plug PCI Controller Driver version: 0.5
[    0.250318] ACPI: Added _OSI(Module Device)
[    0.250322] ACPI: Added _OSI(Processor Device)
[    0.250324] ACPI: Added _OSI(3.0 _SCP Extensions)
[    0.250327] ACPI: Added _OSI(Processor Aggregator Device)
[    0.250330] ACPI: Added _OSI(Linux-Dell-Video)
[    0.250332] ACPI: Added _OSI(Linux-Lenovo-NV-HDMI-Audio)
[    0.250334] ACPI: Added _OSI(Linux-HPI-Hybrid-Graphics)
[    0.263197] ACPI: 10 ACPI AML tables successfully acquired and loaded
[    0.265332] ACPI: [Firmware Bug]: BIOS _OSI(Linux) query ignored
[    0.267916] ACPI: EC: EC started
[    0.267919] ACPI: EC: interrupt blocked
[    0.268084] ACPI: EC: EC_CMD/EC_SC=0x666, EC_DATA=0x662
[    0.268088] ACPI: \_SB_.PCI0.LPC0.H_EC: Boot DSDT EC used to handle transactions
[    0.268091] ACPI: Interpreter enabled
[    0.268117] ACPI: PM: (supports S0 S3 S4 S5)
[    0.268119] ACPI: Using IOAPIC for interrupt routing
[    0.268296] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
[    0.268772] ACPI: Enabled 4 GPEs in block 00 to 1F
[    0.279692] ACPI: PCI Root Bridge [PCI0] (domain 0000 [bus 00-ff])
[    0.279701] acpi PNP0A08:00: _OSC: OS supports [ExtendedConfig ASPM ClockPM Segments MSI EDR HPX-Type3]
[    0.279794] acpi PNP0A08:00: _OSC: platform does not support [SHPCHotplug LTR DPC]
[    0.279958] acpi PNP0A08:00: _OSC: OS now controls [PCIeHotplug PME AER PCIeCapability]
[    0.279960] acpi PNP0A08:00: FADT indicates ASPM is unsupported, using BIOS configuration
[    0.279972] acpi PNP0A08:00: [Firmware Info]: MMCONFIG for domain 0000 [bus 00-3f] only partially covers this bridge
[    0.291195] ACPI: PCI: Interrupt link LNKA configured for IRQ 0
[    0.291273] ACPI: PCI: Interrupt link LNKB configured for IRQ 0
[    0.291331] ACPI: PCI: Interrupt link LNKC configured for IRQ 0
[    0.291405] ACPI: PCI: Interrupt link LNKD configured for IRQ 0
[    0.291474] ACPI: PCI: Interrupt link LNKE configured for IRQ 0
[    0.291529] ACPI: PCI: Interrupt link LNKF configured for IRQ 0
[    0.291582] ACPI: PCI: Interrupt link LNKG configured for IRQ 0
[    0.291634] ACPI: PCI: Interrupt link LNKH configured for IRQ 0
[    0.296303] ACPI: EC: interrupt unblocked
[    0.296305] ACPI: EC: event unblocked
[    0.296317] ACPI: EC: EC_CMD/EC_SC=0x666, EC_DATA=0x662
[    0.296319] ACPI: EC: GPE=0x4
[    0.296321] ACPI: \_SB_.PCI0.LPC0.H_EC: Boot DSDT EC initialization complete
[    0.296323] ACPI: \_SB_.PCI0.LPC0.H_EC: EC: Used to handle transactions and events
[    0.296688] ACPI: bus type USB registered
[    0.302934] PCI: Using ACPI for IRQ routing
[    0.308089] pnp: PnP ACPI init
[    0.310420] pnp: PnP ACPI: found 5 devices
[    0.318432] clocksource: acpi_pm: mask: 0xffffff max_cycles: 0xffffff, max_idle_ns: 2085701024 ns
[    0.903750] ACPI: AC: AC Adapter [ADP1] (off-line)
[    0.903831] ACPI: button: Power Button [PWRB]
[    0.903894] ACPI: button: Lid Switch [LID0]
[    0.904032] ACPI: button: Power Button [PWRF]
[    0.904144] ACPI: \_PR_.C000: Found 2 idle states
[    0.904337] ACPI: \_PR_.C001: Found 2 idle states
[    0.904478] ACPI: \_PR_.C002: Found 2 idle states
[    0.904588] ACPI: \_PR_.C003: Found 2 idle states
[    0.904998] ACPI: thermal: Thermal Zone [TZ01] (20 C)
[    0.928238] ACPI: bus type drm_connector registered
[    0.932397] ACPI: battery: Slot [BAT0] (battery present)
[    2.317278] ACPI: video: Video Device [VGA] (multi-head: yes  rom: no  post: no)
[    2.318041] acpi device:0c: registered as cooling_device4
[    2.368206] acpi PNP0C14:01: duplicate WMI GUID 05901221-D566-11D1-B2F0-00A0C9062910 (first instance was on PNP0C14:00)
[    2.392004] acpi PNP0C14:02: duplicate WMI GUID 05901221-D566-11D1-B2F0-00A0C9062910 (first instance was on PNP0C14:00)
[    2.425740] mmc0: SDHCI controller on ACPI [AMDI0041:00] using ADMA
[    8.208644] acpi_cpufreq: overriding BIOS provided _PSD data
[    8.904061] ideapad_acpi VPC2004:00: Keyboard backlight control not available
[    9.124598] ideapad_acpi VPC2004:00: DYTC interface is not available
[steve@fedora ~]$ 
```

Okay, that's rather a lot. Let's pull out some interesting sections.

## ACPI Tables

ACPI is made up of a bunch of tables that identify devices, functions or other things in the system BIOS. There's a large section at the beginning, running until this message:

```shell
[    0.008697] ACPI: Reserving SSDT table memory at [mem 0xc91be000-0xc91be742]
```

All of that simply describes which tables are available and where they end up in system memory. Not really interesting to us.

## ACPI Init

The next section has to do with initalizing the ACPI bus, what features are supported, starting the PCI and USB busses, etc, etc. Again, not really interesting to us at this point, because it doesn't have much to do with specific devices.  This section runs through this message:

```shell
[    0.302934] PCI: Using ACPI for IRQ routing
```

## Initializing ACPI Devices

Next up we get a section of initializing the actual ACPI devices, starting here:

```shell
[    0.308089] pnp: PnP ACPI init
[    0.310420] pnp: PnP ACPI: found 5 devices
```

`PnP` most likely stands for "Plug and Play", indicating that not only are these actual devices, they're intended to either be able to come and go and/or be somewhat universal.

So what are those devices? well, that comes next...

```shell
[    0.903750] ACPI: AC: AC Adapter [ADP1] (off-line)
[    0.903831] ACPI: button: Power Button [PWRB]
[    0.903894] ACPI: button: Lid Switch [LID0]
[    0.904032] ACPI: button: Power Button [PWRF]
[    0.904144] ACPI: \_PR_.C000: Found 2 idle states
[    0.904337] ACPI: \_PR_.C001: Found 2 idle states
[    0.904478] ACPI: \_PR_.C002: Found 2 idle states
[    0.904588] ACPI: \_PR_.C003: Found 2 idle states
[    0.904998] ACPI: thermal: Thermal Zone [TZ01] (20 C)
[    0.928238] ACPI: bus type drm_connector registered
[    0.932397] ACPI: battery: Slot [BAT0] (battery present)
[    2.317278] ACPI: video: Video Device [VGA] (multi-head: yes  rom: no  post: no)
[    2.318041] acpi device:0c: registered as cooling_device4
```

First, ACPI detects that there's a power datapter, two power buttons, and a lid switch. I'm not sure what the two power buttons thing is about - perhaps one is just a software button? In this context, lid switch is a switch that activates when the lid is closed, not the missing tablet mode switch. I'm basing that on the behavior of the machines - it can detect when the lid is closed, but not when it's in tablet mode. So even if it is the right device, it's not fully supported yet.

Then we get messages about idle states. These are related to some device, but I don't know which. And since we're looking for a button, I don't care.

Finally, we get some more devices: a "[thermal zone](https://learn.microsoft.com/en-us/windows-hardware/drivers/bringup/acpi-defined-devices#thermal-zones)" (for managing the cooling of the system), a battery, and a VGA output. 

Next, we have some messages about devices that show up twice and about other things using ACPI devices.

```shell
[    2.368206] acpi PNP0C14:01: duplicate WMI GUID 05901221-D566-11D1-B2F0-00A0C9062910 (first instance was on PNP0C14:00)
[    2.392004] acpi PNP0C14:02: duplicate WMI GUID 05901221-D566-11D1-B2F0-00A0C9062910 (first instance was on PNP0C14:00)
[    2.425740] mmc0: SDHCI controller on ACPI [AMDI0041:00] using ADMA
[    8.208644] acpi_cpufreq: overriding BIOS provided _PSD data
```

Finally, we have a couple messages about things the system can't do.

```shell
[    8.904061] ideapad_acpi VPC2004:00: Keyboard backlight control not available
[    9.124598] ideapad_acpi VPC2004:00: DYTC interface is not available
```

These are probably correct: as far as I can tell, there really isn't a keyboard backlight. `DYTC` appears to be some sort of detection for whether a device is on a desk or a lap, per [kernel thinkpad-acpi documentation](https://www.kernel.org/doc/html/latest/admin-guide/laptops/thinkpad-acpi.html#dytc-lapmode-sensor). The next step will let us determine if the system actually doesn't have support.

One reason I want to separate out these messages is that they point to the existance/loading of a `ideapad_acpi` driver. At a guess, this implements ACPI support that is specific to ideapad laptops. Lenovo doesn't advertise this machine as an ideapad, but I guess it technically is -- it's certianly no thinkpad!

So what have we learned examining `dmesg` output? That the ACPI bus works, that there's no indicator the laptop/slate mode switch is detected, and that there's an `ideapad_acpi` driver that is most likely where we'll end up adding support.

What's next? A bit of an ACPI primer, then we'll start digging through the ACPI data available to us to see what's happening.

# ACPI Primer

ACPI (Advanced Configuration and Power Interface) is the way modern hardware describes itself for operating systems. It's technically part of the UEFI specification, and [the latest version can be found on this page](https://uefi.org/specifications).

What do we care about here? Mostly that ACPI is made up of tables. There are certain standard table names which determine what is in each table. A BIOS can include other tables, but they may not get properly parsed by any particular operating system.

A table is made up of entries, where an entry can be a method, a device or other things. But again, a lot is determined by names.

From here we'd be getting into the weeds of how ACPI works. Let's start some investigation and we'll add more ACPI information as needed.

# Dumping ACPI

So we want to look at the ACPI tables of a system. How do we do so? We use two tools: one to dump the tables to disk, called `acpidump` and one to disassemble them, called `iasl`. Both are part of the `acpica-tools` package, so let's install that:

```shell
[steve@fedora ~]$ sudo dnf install acpica-tools
[snip]

Installed:
  acpica-tools-20220331-4.fc37.x86_64                                                                                                                                       

Complete!
[steve@fedora ~]$ 
```

Next, we'll create a directory to dump the ACPI tables into and `cd` into it:
```shell
[steve@fedora ~]$ mkdir acpidump
[steve@fedora ~]$ cd acpidump/
[steve@fedora acpidump]$ 
```

We do this because the next step creates a bunch of files -- best to have them separate from others.

So, let's dump the ACPI tables. We'll do this in a binary format, because otherwise we just get a bunch of stuff dumped to the console.

```shell
[steve@fedora acpidump]$ sudo acpidump -b
[sudo] password for steve: 
[steve@fedora acpidump]$ ls
```

What did that produce? well, let's look in the directory:

```shell
[steve@fedora acpidump]$ ls
apic.dat  crat.dat  fpdt.dat  msdm.dat   ssdt3.dat  ssdt7.dat  uefi.dat
batb.dat  dsdt.dat  hpet.dat  sbst.dat   ssdt4.dat  ssdt8.dat  vfct.dat
bgrt.dat  facp.dat  ivrs.dat  ssdt1.dat  ssdt5.dat  ssdt9.dat  wsmt.dat
cdit.dat  facs.dat  mcfg.dat  ssdt2.dat  ssdt6.dat  tpm2.dat
[steve@fedora acpidump]$
```

Okay, we got files! Unfortunately, they're still in a binary format. This is where `iasl` comes in. These files are currentyl binary ACPI machine language files. In other words: compiled software (runnable in the right context):

```shell
[steve@fedora acpidump]$ file dsdt.dat 
dsdt.dat: ACPI Machine Language file 'DSDT' AMD 1000 by LENOVO, revision 1, 37204 bytes, created by INTL 20180313
```

`iasl` is a compiler/decompiler for this type of machine code. So let's have it decompile all of them:

```shell
[steve@fedora acpidump]$ iasl -d *.dat

Intel ACPI Component Architecture
ASL+ Optimizing Compiler/Disassembler version 20220331
Copyright (c) 2000 - 2022 Intel Corporation

File appears to be binary: found 223 non-ASCII characters, disassembling
Binary file appears to be a valid ACPI table, disassembling
Input file apic.dat, Length 0x108 (264) bytes
ACPI: APIC 0x0000000000000000 000108 (v03 LENOVO CB-01    00000000 PTEC 00000002)
Acpi Data Table [APIC] decoded
Formatted output:  apic.dsl - 12899 bytes

[snip]

File appears to be binary: found 17 non-ASCII characters, disassembling
Binary file appears to be a valid ACPI table, disassembling
Input file wsmt.dat, Length 0x28 (40) bytes
ACPI: WSMT 0x0000000000000000 000028 (v01 LENOVO CB-01    00000000 PTEC 00000002)
Acpi Data Table [WSMT] decoded
Formatted output:  wsmt.dsl - 1323 bytes
```

Now what do we have?

```shell
[steve@fedora acpidump]$ ls
apic.dat  cdit.dsl  facs.dat  ivrs.dsl  ssdt1.dat  ssdt4.dsl  ssdt8.dat  uefi.dsl
apic.dsl  crat.dat  facs.dsl  mcfg.dat  ssdt1.dsl  ssdt5.dat  ssdt8.dsl  vfct.dat
batb.dat  crat.dsl  fpdt.dat  mcfg.dsl  ssdt2.dat  ssdt5.dsl  ssdt9.dat  vfct.dsl
batb.dsl  dsdt.dat  fpdt.dsl  msdm.dat  ssdt2.dsl  ssdt6.dat  ssdt9.dsl  wsmt.dat
bgrt.dat  dsdt.dsl  hpet.dat  msdm.dsl  ssdt3.dat  ssdt6.dsl  tpm2.dat   wsmt.dsl
bgrt.dsl  facp.dat  hpet.dsl  sbst.dat  ssdt3.dsl  ssdt7.dat  tpm2.dsl
cdit.dat  facp.dsl  ivrs.dat  sbst.dsl  ssdt4.dat  ssdt7.dsl  uefi.dat
[steve@fedora acpidump]$
```

A bunch of `.dsl` files. Feel free to go poking into some. They tend to be long, so I'll put some full ones at the bottom of this entry.

# Looking for Identifiers

What's next? Let's look for some of the identifiers we gathered. We've got a BIOS name that ends in `CIND`, a compatible ID of `PNP0C60`, and a hardware ID that ends in `AMDI0081`. I wonder if we'll find any of those anywhere?

```shell
[steve@fedora acpidump]$ grep -riIn CIND *.dsl
ssdt8.dsl:138:        Device (CIND)
[steve@fedora acpidump]$ grep -riIn PNP0C60 *.dsl
ssdt8.dsl:141:            Name (_CID, "PNP0C60" /* Display Sensor Device */)  // _CID: Compatible ID
[steve@fedora acpidump]$ grep -riIn AMDI0081 *.dsl
ssdt8.dsl:140:            Name (_HID, "AMDI0081")  // _HID: Hardware ID
[steve@fedora acpidump]$
```

Well that's pretty clear! This device appears to be defined in the SSDT8 table. What is that? Let's refer to the [Linux kernel's summary](https://www.kernel.org/doc/html/latest/arm64/acpi_object_usage.html):

"These tables are a continuation of the DSDT; these are recommended for use with devices that can be added to a running system, but can also serve the purpose of dividing up device descriptions into more manageable pieces."

Okay, so what's a DST table?

"Differentiated System Description Table

A DSDT is required; see also SSDT.

ACPI tables contain only one DSDT but can contain one or more SSDTs, which are optional. Each SSDT can only add to the ACPI namespace, but cannot modify or replace anything in the DSDT."

That's clear as mud... But what it means is that the DSDT (and by extension SSDTs) contain is a list of devices that are in the system.  Since we're looking for a device, finding it in the SSDT makes sense.

## Examining the Device

What does the device actually look like?

```shell
    Scope (\_SB)
    {
        Device (CIND)
        {
            Name (_HID, "AMDI0081")  // _HID: Hardware ID
            Name (_CID, "PNP0C60" /* Display Sensor Device */)  // _CID: Compatible ID
            Name (_UID, 0x00)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((M049 (M128, 0x7A) == 0x01))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (0x00)
                }
            }
        }
    
    ...

    }
```

And there's the device! With all three identifiers, even. Looks like we found it. But... What does that all mean?

Let's break it down line-by-line:

```
    Scope (\_SB)
    {
```

This says that everything inside it is within the ACPI namespace `_SB`.

```
        Device (CIND)
        {
```

Everything inside this is attributes and methods of a divice named `CIND`.

```
            Name (_HID, "AMDI0081")  // _HID: Hardware ID
            Name (_CID, "PNP0C60" /* Display Sensor Device */)  // _CID: Compatible ID
            Name (_UID, 0x00)  // _UID: Unique ID
```

Identifiers for the device:
* `_HID` is the [Hardware ID](https://uefi.org/specs/ACPI/6.5/06_Device_Configuration.html#hid-hardware-id) and gives a useful identifier for devices.
* `_SID` is the [Compatible ID](https://uefi.org/specs/ACPI/6.5/06_Device_Configuration.html#cid-compatible-id) and says that this deivce is compatible with another identifier -- either a stnadard interface or otherwise emulating that interface.
* `_UID` is a [Unique ID](https://uefi.org/specs/ACPI/6.5/06_Device_Configuration.html#uid-unique-id), used to make sure that the BIOS/OS can differentiate between multiple instances of the same device, if multiple are present.

`_HID` and `_CID` use ACPI and PNP identifiers. These are vendor-specific and you can tell which vendor based on the prefix. PNP identifiers are 3 letters, while ACPI are 4. So let's look up the two we've got:

* `PNP0C60` is a [Microsoft identifier](https://uefi.org/PNP_ID_List?search=PNP)
* `AMDI0081` is an [AMD identifier](https://uefi.org/ACPI_ID_List?search=AMDI)

Knowing who owns the identifier isn't very useful on its own, but it does tell us where we may want ot look for more documentation later.

Okay, onwards:

```
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((M049 (M128, 0x7A) == 0x01))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (0x00)
                }
            }
        }
```

`iasl` very kindly tells us that this is a method named _STA for getting status. But of what?

## The `_STA` Method

The ACPI documentation says _STA returns the "[current status of a device, which can be one of the following: enabled, disabled, or removed](https://uefi.org/specs/ACPI/6.5/06_Device_Configuration.html#sta-device-status)".

It also gives us a nice table for the return value:

* Bit [0] - Set if the device is present.
* Bit [1] - Set if the device is enabled and decoding its resources.
* Bit [2] - Set if the device should be shown in the UI.
* Bit [3] - Set if the device is functioning properly (cleared if device failed its diagnostics).
* Bit [4] - Set if the battery is present.

So this can return 0x0 or 0xf. Returning zero would mena not present, not enabled, should not be shown in the UI and is not functioning properly. 0xF decodes to 0b1111, indicating the device is present, enabled, should be shown in the UI and is functioning properly.

So let's look at the if statement:

```If ((M049 (M128, 0x7A) == 0x01))```

It's calling M049, a method with the arguments M128 and 0x7A, then checking if the result is 1.

### `M128`

Okay, what's M128?

```shell
[steve@fedora acpidump]$ grep -n M128 ssdt8.dsl 
89:    External (M128, FieldUnitObj)
145:                If ((M049 (M128, 0x7A) == 0x01))
166:                If ((M049 (M128, 0x7A) == 0x01))
[steve@fedora acpidump]$
```

The first result tells us that it's a `FieldUnitObj` that's external to the `ssdt8` table. Let's start with what a `FieldUnitObj` is.

Turns out it's really hard to find out. [Others have tried and found no documentation](https://www.reddit.com/r/hackintosh/comments/tqkkrt/trying_to_fix_my_ssdts_cannot_find_documentation/). A search of the ACPI specification [includes `FieldUnitObj`, but only as a part of the language specification](https://uefi.org/specs/ACPI/6.5/search.html?q=FieldUnitObj&check_keywords=yes&area=default) -- it totally fails to actually *specify* it.

It looks like this is probably a way to access [`Field`s](https://uefi.org/specs/ACPI/6.5/19_ASL_Reference.html?highlight=fieldunit#field-declare-field-objects), which are ways to access other ACPI elements. I think so that one can make properties of one ACPI element available to others. It looks like we'll have to find the definition of M128 in order for it to make sense.

Nonetheless, this means something should be exporting `M128`, so let's look for that:

```shell
[steve@fedora acpidump]$ grep -riIn M128
ssdt5.dsl:121:    External (M128, FieldUnitObj)
ssdt7.dsl:127:        M128,   32, 
ssdt7.dsl:1861:        Local0 = M049 (M128, 0x67)
ssdt7.dsl:1882:        Local0 = M049 (M128, 0x67)
ssdt9.dsl:92:    External (M128, FieldUnitObj)
ssdt8.dsl:89:    External (M128, FieldUnitObj)
ssdt8.dsl:145:                If ((M049 (M128, 0x7A) == 0x01))
ssdt8.dsl:166:                If ((M049 (M128, 0x7A) == 0x01))
ssdt6.dsl:105:    External (M128, FieldUnitObj)
[steve@fedora acpidump]$
```

Hm. Okay, so nothing exports M128, just refers to it. It's odd that `ssdt7` refers to it without an `External` declarator, so let's go look at it:

```
    OperationRegion (CPNV, SystemMemory, 0xCE568018, 0x000100C9)
    Field (CPNV, AnyAcc, Lock, Preserve)
    {
        M082,   32, 
        M083,   32, 
        M084,   32,
        [snip]
        M128,   32,   
        [snip]
    }
```

(The first chunk starts at line 60 and line 127 has the actual definition).

Just as I suspected, `M128` is part of a field! And now we have the definition of it. Looking at this, M128 is part of an `OperationRegion`. The ACPI spec gives an `OperationRegion` the following structure:

```
OperationRegion (
    RegionName, // NameString
    RegionSpace, // RegionSpaceKeyword
    Offset, // TermArg => Integer
    Length // TermArg => Integer
)
```

### What Memory does that Refer to?

So it looks like this region is a chunk of system memory starting at `0xCE568018`. Presumably with the full memory layout we could know what's in this location.

Hm. `dmesg`` tells us a lot about system memory layout. Does it tell us what's there?

Unfortunately, this turned out to be a manual hunt through the (early) `dmesg` output. But I did find something referring ot this memory region!

```
[    0.000000] reserve setup_data: [mem 0x00000000cc57e000-0x00000000ce57dfff] ACPI NVS
```

So what is ACPI NVS? Some quick searching [brings us back to the ACPI spec](https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/15_System_Address_Map_Interfaces/Sys_Address_Map_Interfaces.html), which says:

"This range of addresses is in use or reserved by the system and must not be used by the operating system. This range is required to be saved and restored across an NVS sleep."

That doesn't really explain it, other than "the OS doesn't touch here". Therefore, this is probably a range where the BIOS and/or devices can communicate with various things. In this case, I suspect the memory is being used by the system to communicate between devices and the BIOS and/or OS drivers. Probably that specific range is just a place the sensor can give a status report!

## M049

Moving back into the `_STA` method, the value from `M128` is passed to another method like this:

```
If ((M049 (M128, 0x7A) == 0x01))
```

So now we need to find out what `M049` does. Let's see where it's defined:

```shell
[steve@fedora acpidump]$ grep -riIn 'Method.*M049'
ssdt7.dsl:1513:    Method (M049, 2, Serialized)
[steve@fedora acpidump]$
```

Okay, `ssdt7` again.

And we see it looks like this:

```
    Method (M049, 2, Serialized)
    {
        Local0 = 0x00
        If ((Arg0 != 0x00))
        {
            Local0 = M011 (Arg0, Arg1, 0x00, 0x08)
        }

        Return (Local0)
    }
```

This meothd checks if the first argument is 0. If it is zero, it simply returns 0. Otherwise, it calls `M011` with four arguments.

So let's see what M011 is...

## M011

Predictably, `M011` is in `ssdt7`:

```shell
[steve@fedora acpidump]$ grep -riIn 'Method.*M011'
ssdt7.dsl:552:    Method (M011, 4, Serialized)
[steve@fedora acpidump]$ 
```

And the text:

```
    Method (M011, 4, Serialized)
    {
        Local0 = (Arg0 + Arg1)
        OperationRegion (VARM, SystemMemory, Local0, 0x01)
        Field (VARM, ByteAcc, NoLock, Preserve)
        {
            VARR,   8
        }

        Local1 = VARR /* \M011.VARR */
        Local2 = ((Local1 >> Arg2) & (0xFF >> (0x08 - Arg3)
            ))
        Return (Local2)
    }
```

Well that's somewhat complicated. So we start by setting a variable to the sum of the first two arguments. Then we use that as an address in memory to fetch a single byte from, which becomes `Local1`. `Local1` is then right shifted by `Arg2` (the third argument) bytes, and binary `and`ed with 0xFF shifted right by `0x08 - Arg3` bytes. This is all stored in `Local2` and returned.

Let's plug in some values and see what we get.

* `Arg0` is the value we got from `M128`. No idea what this is.
* `Arg1` is `0x7A` (from `_STA`, via `M049`)
* `Arg2` is `0x00` (from `M049`)
* `Arg3` is `0x08` (from `M049`)

If we substitute these values in to the function, we see:

```
    Method (M011, 4, Serialized)
    {
        Local0 = (M128 + 0x7A)
        OperationRegion (VARM, SystemMemory, Local0, 0x01)
        Field (VARM, ByteAcc, NoLock, Preserve)
        {
            VARR,   8
        }

        Local1 = VARR /* \M011.VARR */
        Local2 = ((Local1 >> 0x00) & (0xFF >> (0x08 - 0x08)
            ))
        Return (Local2)
    }
```

That `Local2` line can be drastically simplified:

```
        Local2 = ((Local1 >> 0x00) & (0xFF >> (0x08 - 0x08)
            ))
```

Right shift by 0 bytes means no action. `0x08 - 0x08` is equal to 0

```
        Local2 = ((Local1) & (0xFF >> 0x00))
```

`0xFF` shifted right by `0x00` is `0xFF`:

```
        Local2 = ((Local1) & (0xFF))
```

And any value binary `and`ed with 0xFF is itself (binary `and` with 0xFF is an identity function):

```
        Local2 = Local1
```

So `Local2` is `Local1`.  Let's plug that into the whole function:

```
    Method (M011, 4, Serialized)
    {
        Local0 = (M128 + 0x7A)
        OperationRegion (VARM, SystemMemory, Local0, 0x01)
        Field (VARM, ByteAcc, NoLock, Preserve)
        {
            VARR,   8
        }

        Local1 = VARR /* \M011.VARR */
        Local2 = Local1
        Return (Local2)
    }
```

Simplifying that ( to eliminate `Local2`):

```
    Method (M011, 4, Serialized)
    {
        Local0 = (M128 + 0x7A)
        OperationRegion (VARM, SystemMemory, Local0, 0x01)
        Field (VARM, ByteAcc, NoLock, Preserve)
        {
            VARR,   8
        }

        Local1 = VARR /* \M011.VARR */
        Return (Local1)
    }
```

So the whole function, in sum:

* Takes the value read from `M128`
* Adds `0x7A` to it
* Reads a byte, and 
* Returns that

To me this implies a specific structure, though I don't currently have the edidence to back it up as solid conclusions. It implies to me that there's some table kept in memory (probably the one at `0xCE568018`) that points to where other things are loaded in memory. `M128` is the entry in that for the one that includes the laptop/slate indicator. And then at an offset of `0x7A` from the beginning of that table, there's a byte (or a bit) indicating status.

But again, no evidence os this specific configuration. If we wanted to, we could go digging through system memory and prove (or disprove) this theory. However, if the bit is actually just an indicator that the hardware is present, we might never see it change.

## Concluding `_STA`

At this point, in my opinion, we've dug deep enough inot `_STA` to believe that it probably does exactly what it says: provides status on whether or not the device is present.

It's possible that the `_STA` method could be being used to report where the lid is. However, I beleive that wouldn't be compliant with the ACPI specification, which only allows enabled, disabled, or removed. Instead, let's cross that bridge when we get to it.

However, in the interest of not getting bogged down, let's move on.

# DYTC

Earlier, we saw an error about DYTC (for detecting it it's on a lap or a desk) not being supported. Some quick online investigation shows that if DYTC is supported, [there should be a `VPC2004` device with a `DYTC` method](https://bugzilla.kernel.org/show_bug.cgi?id=212985#c1).

So does this system support it?

```shell
[steve@fedora acpidump]$ grep -riIn VPC2004 *.dsl
dsdt.dsl:4895:                        Name (_HID, "VPC2004")  // _HID: Hardware ID
[steve@fedora acpidump]$ grep -riIn DYTC *.dsl
[steve@fedora acpidump]$
```

So it looks like this system has a device that matches the identifier, but no DYTC support. And therefore it does not support this sensor, just as `dmesg` told us.

# Up next

Next we'll take a look at the standards this device implements and figure out what driver to add support to.

# Long output

## Full SSDT8

```shell
/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20220331 (64-bit version)
 * Copyright (c) 2000 - 2022 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of ssdt8.dat, Sat Nov 12 04:21:01 2022
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000045F (1119)
 *     Revision         0x01
 *     Checksum         0x82
 *     OEM ID           "LENOVO"
 *     OEM Table ID     "AmdTable"
 *     OEM Revision     0x00000001 (1)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20180313 (538444563)
 */
DefinitionBlock ("", "SSDT", 1, "LENOVO", "AmdTable", 0x00000001)
{
    External (_SB_.PCI0.GP17.MP2C, DeviceObj)
    External (M037, DeviceObj)
    External (M046, DeviceObj)
    External (M047, DeviceObj)
    External (M049, MethodObj)    // 2 Arguments
    External (M050, DeviceObj)
    External (M051, DeviceObj)
    External (M052, DeviceObj)
    External (M053, DeviceObj)
    External (M054, DeviceObj)
    External (M055, DeviceObj)
    External (M056, DeviceObj)
    External (M057, DeviceObj)
    External (M058, DeviceObj)
    External (M059, DeviceObj)
    External (M062, DeviceObj)
    External (M068, DeviceObj)
    External (M069, DeviceObj)
    External (M070, DeviceObj)
    External (M071, DeviceObj)
    External (M072, DeviceObj)
    External (M074, DeviceObj)
    External (M075, DeviceObj)
    External (M076, DeviceObj)
    External (M077, DeviceObj)
    External (M078, DeviceObj)
    External (M079, DeviceObj)
    External (M080, DeviceObj)
    External (M081, DeviceObj)
    External (M082, FieldUnitObj)
    External (M083, FieldUnitObj)
    External (M084, FieldUnitObj)
    External (M085, FieldUnitObj)
    External (M086, FieldUnitObj)
    External (M087, FieldUnitObj)
    External (M088, FieldUnitObj)
    External (M089, FieldUnitObj)
    External (M090, FieldUnitObj)
    External (M091, FieldUnitObj)
    External (M092, FieldUnitObj)
    External (M093, FieldUnitObj)
    External (M094, FieldUnitObj)
    External (M095, FieldUnitObj)
    External (M096, FieldUnitObj)
    External (M097, FieldUnitObj)
    External (M098, FieldUnitObj)
    External (M099, FieldUnitObj)
    External (M100, FieldUnitObj)
    External (M101, FieldUnitObj)
    External (M102, FieldUnitObj)
    External (M103, FieldUnitObj)
    External (M104, FieldUnitObj)
    External (M105, FieldUnitObj)
    External (M106, FieldUnitObj)
    External (M107, FieldUnitObj)
    External (M108, FieldUnitObj)
    External (M109, FieldUnitObj)
    External (M110, FieldUnitObj)
    External (M115, BuffObj)
    External (M116, BuffFieldObj)
    External (M117, BuffFieldObj)
    External (M118, BuffFieldObj)
    External (M119, BuffFieldObj)
    External (M120, BuffFieldObj)
    External (M122, FieldUnitObj)
    External (M127, DeviceObj)
    External (M128, FieldUnitObj)
    External (M131, FieldUnitObj)
    External (M132, FieldUnitObj)
    External (M133, FieldUnitObj)
    External (M134, FieldUnitObj)
    External (M135, FieldUnitObj)
    External (M136, FieldUnitObj)
    External (M220, FieldUnitObj)
    External (M221, FieldUnitObj)
    External (M226, FieldUnitObj)
    External (M227, DeviceObj)
    External (M229, FieldUnitObj)
    External (M231, FieldUnitObj)
    External (M233, FieldUnitObj)
    External (M235, FieldUnitObj)
    External (M251, FieldUnitObj)
    External (M280, FieldUnitObj)
    External (M290, FieldUnitObj)
    External (M310, FieldUnitObj)
    External (M320, FieldUnitObj)
    External (M321, FieldUnitObj)
    External (M322, FieldUnitObj)
    External (M323, FieldUnitObj)
    External (M324, FieldUnitObj)
    External (M325, FieldUnitObj)
    External (M326, FieldUnitObj)
    External (M327, FieldUnitObj)
    External (M328, FieldUnitObj)
    External (M329, DeviceObj)
    External (M330, DeviceObj)
    External (M378, FieldUnitObj)
    External (M379, FieldUnitObj)
    External (M380, FieldUnitObj)
    External (M381, FieldUnitObj)
    External (M382, FieldUnitObj)
    External (M383, FieldUnitObj)
    External (M384, FieldUnitObj)
    External (M385, FieldUnitObj)
    External (M386, FieldUnitObj)
    External (M387, FieldUnitObj)
    External (M388, FieldUnitObj)
    External (M389, FieldUnitObj)
    External (M390, FieldUnitObj)
    External (M391, FieldUnitObj)
    External (M392, FieldUnitObj)
    External (M404, DeviceObj)

    Scope (\_SB)
    {
        Device (CIND)
        {
            Name (_HID, "AMDI0081")  // _HID: Hardware ID
            Name (_CID, "PNP0C60" /* Display Sensor Device */)  // _CID: Compatible ID
            Name (_UID, 0x00)  // _UID: Unique ID
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((M049 (M128, 0x7A) == 0x01))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (0x00)
                }
            }
        }

        Device (VGBI)
        {
            Name (_HID, "AMDI0080")  // _HID: Hardware ID
            Name (_UID, 0x01)  // _UID: Unique ID
            Name (_DEP, Package (0x01)  // _DEP: Dependencies
            {
                \_SB.PCI0.GP17.MP2C
            })
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                If ((M049 (M128, 0x7A) == 0x01))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (0x00)
                }
            }
        }
    }
}
```
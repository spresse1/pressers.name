---
title: "Fixing Linux Unsupported Devices on the Lenovo 300e Gen 2"
date: 2022-11-07T19:00:00+02:00
---

I got a [Lenovo 300e](https://www.lenovo.com/us/en/p/laptops/lenovo/lenovo-edu-chromebooks/lenovo-300e-2nd-gen-amd/82gk001uus) (with Windows) from a Lenovo sale (for $126!). It seems to be a neat little machine - but it doesn't fully work under Linux. As far as I know, cheap machines like this tend to be built with cheap parts, which tend not to be new, but instead minor additions or changes to new ones. Manufacturers often give these new device IDs, which sometimes means drivers don't support them. I'm hoping that's the case here.

![Lenovo 300e AMD laptop, shown in four different postions. It's a laptop with a 360 degree hinge. Shown top-right, as a laptop. Bottom-right as a tablet, with the keyboard on the table. Bottom-left as a tent, with the hinge at the top of the system. And top-left as a tablet-stand, with the keyboard on the table, effectively halfway to tablet mode.](https://p1-ofp.static.pub/medias/bWFzdGVyfHJvb3R8ODI5MjZ8aW1hZ2UvcG5nfGgzZS9oYjgvMTEwOTY0Mjk5ODU4MjIucG5nfDQ2MzQ0MjhmOTYyZGZjMzQyMjYwMGY4YWYyOGVkNGRjYWRiZWE5M2VhMDI5MmQyZWE4OWI0MWZjYWEwOWI4Yjg/bWFzdGVyfH.png)

I tried this with an older Lenovo Yoga machine and it turned out the sensor for laptop/tablet mode did some weird accelerometer-based stuff. I figured out how it worked, but was never able to get the system fully working. So let's hope this one goes better!

# The Plan

My plan with this device is pretty simple, at least at a high level:

1. Identify non-working devices
2. Gather identifiers 
3. Determine if existing drivers work for those devices
4. If yes, add support to those drivers
5. If not, is there anything close we can borrow from?
6. If yes, borrow
7. If no, consider writing fresh, if possible

The big caveat is that I don't have a ton of experience doing kernel development. I've looked at non-linux kernels for class and I [updated a broken driver]({{< relref "/blog/acm-cluster/building-myricom-fiber-rpms" >}}) once, but that's it. I've never written a device driver from scratch and never successfully added a device that didn't have a driver known to work in the past. This means I'll pprobably go down some rabbit holes and do this in an inefficient way, but hopefully it can be something others can learn from too.

So let's get started!

# What doesn't work?

At a first pass, the devices that dont work are:

* Non-functional touchpad
* No laptop/tablet mode switch (meaning that the keyboard is always active, even when the device is in tablet mode)

# Gathering Identifiers

The first step in fixing things is to figure out what the non-functional devices actually are. We want to know things like hardware IDs, what busses they're on, who the manufacturers are, etc. Since this machine runs Windows, I can poke at them through that.

So off to the Windows Device Manager!

![Windows Device Manager Screenshot, with Human Interface Devices Expanded and "GPIO Laptop or Slate Indicator Driver highlighted](/static/images/300e/Devices.PNG)

In this case we've gotten lucky and two of the devices have names that fairly obviously match the hardware we're looking for -- "GPIO Laptop or Slate Indicator Driver" and "HID-compliant touch pad". If they didn't we'd have to guess which device it is until we get it right.

So how do we know we have the right devices? We disable them and check that the corresponding hardware has stopped funtioning.  In this case, the names were spot-on and these are the correct devices.

## Collecting Identifiers

Next, we'll collect identifiers for each of these devices that might be useful under linux. This is pretty much any kind of consistent BIOS or hardware name for the device.

Specifically, I pulled the following details:

GPIO Laptop or Slate Indicator:

* BIOS Name: `\_SB.CIND`
* Compatible IDs: `ACPI\PNP0C60` and `PNP0C60`
* Hardware IDs: `ACPI\VEN_AMDI&DEV_0081`, `ACPI\AMDI0081`, `*AMDI0081`
* Device Instance Path: `ACPI\AMDI0081\0`

HID-Compliant Touch Pad:

* Hardware IDs: 
    * `HID\VEN_SYN&DEV_2392&Col02`
    * `HID\SYNA2392&Col02`
    * `HID\*SYNA2392&Col02`
    * `HID\VID_06CB&UP:000D_U:005`
    * `HID_DEVICE_UP:000D_U:0005`
    * `HID_DEVICE`
* Instance path: `HID\SYNA2392&COL02\4&18887E7B&0&0001`


![Device Manager screenshot, showing the "Device Instance Path" property of the "GPIO Laptop or Slate Indicator Driver". The value is "ACPI\AMDI0081\0"](/static/images/300e/SlateIndicatorInstancePath.PNG)

![Device Manager screenshot, showing the "BIOS device name" property of the "GPIO Laptop or Slate Indicator Driver". The value is "\_SB.CIND"](/static/images/300e/SlateIndicatorInstancePath.PNG)

![Device Manager screenshot, showing the "Compatible Ids" property of the "GPIO Laptop or Slate Indicator Driver". The values are "ACPI\PNP0C60" and "PNP0C60"](/static/images/300e/SlateIndicatorCompatibleIDs.PNG)

![Device Manager screenshot, showing the "Hardware ids" property of the "GPIO Laptop or Slate Indicator Driver". The values are "ACPI\VEN_AMDI&DEV0081", "ACPI\AMDI0081" and "*AMDI0081"](/static/images/300e/SlateIndicatorDeviceIDs.PNG)

# Up next...

My next post will involve rebooting to linux and actually beginning the hunt for the devices. I'll drop a link in here once that post is up.
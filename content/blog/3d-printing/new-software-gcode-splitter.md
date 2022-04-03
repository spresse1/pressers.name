---
title: "New software - GCode splitter!"
date: 2014-03-07 02:00:33
slug: "new-software-gcode-splitter"
categories:
  - "3D Printing"
  - "Projects"
---

Over the last few months, I've been silent as I transitioned from the life of a student to the life of a professional.  But!  I have finished that transition (for the most part) and am now back.  I even bring new software with me.

This new software (which has the rather uncreative name "gcode splitter") is a utility for use in 3D printing.  I have acquired a 3D printer for me to experiment with.  The printer I own has one printhead.  However, many of my designs require two or more materials.  (I'm using a lot of "exotics", like conductive or flexible plastics).  It occurred to me that as long as the two materials never shared a layer (or only shared one layer at the interface), I could split the print into parts, change the plastic between prints and thereby end up with multi-material objects.

The code is [available on my github](https://github.com/spresse1/gcode-splitter).  The utility has fairly simple inputs - it takes a (specially formatted) gcode file, followed by the locations in which the print should be split.  Obviously, some limitations exist:

*   The gcode must have special formatting or to have no setup/cooldown instructions
*   Units to determine where to split are only millimeters (mm) or layers (l)
*   The movement instructions must be absolute
*   Layers must be visited sequentially from bottom to top (tool does not work with sequential prints)

There are several major improvements I plan to make to this tool, especially if there is interest:

*   Support for relative movements and layers
*   Support for input gcode which does not go strictly bottom to top
*   Support for additional units
*   Support for adjusting the temperature for each portion of the print
*   Unit tests
*   Installer

I welcome suggestions for additional features to add.  At some point soon, I will probably post pictures of results of printing in this method.  In the meantime, enjoy!
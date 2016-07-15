Website Sources
===============

This repository contains much of the source of my website - at least those
bits which it makes sense to version control.  There are no images, 
binaries, or content in here.

buildenv.sh
-----------

`buildenv.sh` is a script which will (surprise of surprises) build the 
environment required for the website's function.  It builds a django 
virtualenv.  Run as::

  # ./buildenv.sh TARGET_DIRECTORY SETTINGS_FILE

where `TARGET_DIRECTORY` is a possibly-existant target to install or 
update and `SETTINGS_FILE` is a file to append to the generic django 
`settings.py` (if the settings.py file is created by this script - that 
is, if this is a new install).

TODO
----

There are plenty of possible improvements to this.  Among them:

* Updating the settings.py file each time if the settings are different. 

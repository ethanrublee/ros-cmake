Cross-compiling ROS for ARM
===========================

Quick and dirty notes on crosscompiling ROS for arm, while the
workflow stabilizes.  At the moment you have to use natty due to a bug
in the backported ARM crosscompiler for lucid/maverick.

* A natty ARM chroot to run ROS in
* A natty x86_64 chroot to cross-compile in.
* The latest rosbuild2 stuff

Here's the skinny.

First pick a directory to put all of these chroots in.  We'll call it
``DIR`` because we are feeling terribly creative.

Create your ARM chroot
----------------------

Happily, this is easy thanks to `rootstock https://wiki.ubuntu.com/ARM/RootfsFromScratch`. 
::

  cd $DIR
  sudo rootstock \
    --fqdn natty-arm \
    --login login \
    --passwd passwd \
    --imagesize 2G \
    --notarball \
    -d natty \
    --seed build-essential,openssh-server


    
					       


I found a machine where a usb reader works with a 16G microsd card,
but the black plastic microsd->sd adapter sleeve does not.

This page explains how to get the serial console going, if you have
problems with no video on boot:

https://wiki.ubuntu.com/ARM/BeagleEditBootscr





Misc usecases
-------------

I want to compile with syslog, not log4cxx

I don't have wxwidgets but want to compile ros_tutorials.  Turtlesim
uses wxwidgets.

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

Happily, this is easy thanks to
`https://wiki.ubuntu.com/ARM/RootfsFromScratch rootstock`_. 
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


    
					       




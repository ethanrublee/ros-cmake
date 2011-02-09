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


    
					       





Beagleboard
-----------

Install ubuntu maverick per these instructions:
https://wiki.ubuntu.com/ARM/OMAPMaverickInstall

Test board: beagleboard-xM rev B.  I got a 16GB microsd card.

The directions are backwards on that page where you overwrite vmlinuz
and uImage with files retrieved from wget.  Do ``vmlinuz`` first,
(you're overwriting the original), then mount ``boot`` and do
``uImage``.

You'll need a DVI Female End to HDMI Male end adapter, usb keyboard
and mouse.  It is regular sized HDMI.  You need an ethernet cable
plugged in to something with a DHCP server as well.

After that is all said and done you'll boot (sloowly) into ubuntu
maverick netbook remix.  Rejoice that you didn't have to build all of
that yourself.  

I added a user named ``ros``.

Log in, ``ifconfig`` to get the IP of the machine.  Install
``openssh-server``.  Ssh in from your desktop.  Now we can get some
work done.

Install and run ``tasksel``::

  apt-get install tasksel         
  sudo tasksel

and uncheck everything but ``openssh-server``.  This will remove all
of the extraneous "netbook" stuff.  This will take a **long** time,
like hours.  Go do something else.

Now you have to ``aptitude update``, but you don't want to simply
safe-upgrade, just install::

  git-core
  subversion
  gcc
  libboost1.42-all-dev
  libapr-dev
  libaprutil1-dev
  g++
  python-setuptools
  python-yaml
  python-lxml
  python-nose
  avahi-daemon
  avahi-utils
  
  
  easy_install -U rosinstall

my favorite optionals::

  emacs 
  aptitude
  zsh


enable a console on ttyS2:

start networking on boot, add to /etc/network/interfaces::

  auto usb0
  iface usb0 inet dhcp

in /etc/init, create a file ttyS2.conf containing::

  # ttyS2 - getty
  #
  # This service maintains a getty on ttyS2 from the point the system is
  # started until it is shut down again.
  
  start on stopped rc RUNLEVEL=[2345]
  stop on runlevel [!2345]
  
  respawn
  exec /sbin/getty -8 115200 ttyS2
  


Misc usecases
-------------

I want to compile with syslog, not log4cxx

I don't have wxwidgets but want to compile ros_tutorials.  Turtlesim
uses wxwidgets.


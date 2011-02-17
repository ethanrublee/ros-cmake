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
  
.. rubric:: boot script

see also:  https://wiki.ubuntu.com/ARM/BeagleEditBootscr

I made a directory /mnt/tmp, used to mount the boot partition with::

  sudo mount /dev/mmcblk0p1 /mnt/tmp

therein I created a script ``make_scr.sh``::

  #!/bin/sh
  
  echo "making boot.scr from boot.scr.txt"
  
  mkimage -A arm -T script -C none -n "boot script" -d ./boot.script ./boot.scr
  
You can extract the actual script from the ``boot.scr`` with commands
on the wiki page above.





#!/bin/sh -ex

THIRDPARTYDIR=/opt/ros/unstable/3rdparty

if [ ! -d $THIRDPARTY_DIR ] ; then
    sudo mkdir $THIRDPARTYDIR
else
    sudo rm -rf $THIRDPARTYDIR/*
fi
sudo chown `whoami` $THIRDPARTYDIR

git clone git://github.com/straszheim/ros-3rdparty.git
cd ros-3rdparty
make


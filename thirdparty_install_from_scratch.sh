#!/bin/sh -ex

THIRDPARTYDIR=$1

if [ ! -d $THIRDPARTYDIR ] ; then
    sudo mkdir $THIRDPARTYDIR
else
    sudo rm -rf $THIRDPARTYDIR/*
fi
sudo chown `whoami` $THIRDPARTYDIR

git clone git://github.com/straszheim/ros-3rdparty.git $THIRDPARTYDIR/src
cd $THIRDPARTYDIR/src
make INSTALL_PREFIX=$THIRDPARTYDIR



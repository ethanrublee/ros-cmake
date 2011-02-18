#!/bin/sh -e

WORK=work-small
rm -rf $WORK
mkdir $WORK
cd $WORK
ROSINSTALL=ros-cmake-small.rosinstall

wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/$ROSINSTALL

rosinstall -n . $ROSINSTALL

./cmake/convert.sh

mkdir build
cd build
#cmake .. -DCMAKE_INSTALL_PREFIX=/tmp/installed



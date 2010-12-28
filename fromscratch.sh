#!/bin/sh

WORK=work-cmake
rm -rf $WORK

rm -f ros-cmake.rosinstall
wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

rosinstall -n $WORK ros-cmake.rosinstall
cd $WORK

./cmake/doit.sh



#!/bin/sh -e

WORK=work-small
rm -rf $WORK
mkdir $WORK
cd $WORK
ROSINSTALL=ros-cmake-small.rosinstall

wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/rosinstalls/$ROSINSTALL

rosinstall -n . $ROSINSTALL

. ./setup.sh

./cmake/convert.sh

mkdir -p build
cd build
../run_cmake.sh



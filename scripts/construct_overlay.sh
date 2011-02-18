#!/bin/sh -e

ROSINSTALL=ros-cmake-overlay.rosinstall

wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/rosinstalls/$ROSINSTALL

set +e
rosinstall -n . $ROSINSTALL
set -e

STACKS=$(ls */stack.xml | sed -e 's@/stack.xml@@')

ROS_PACKAGE_PATH=`pwd`/../work-small/inst

for s in $STACKS
do
    ROS_PACKAGE_PATH=`pwd`/$s:$ROS_PACKAGE_PATH
done

echo "ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH" > setup.sh

. ./setup.sh

./cmake/convert.sh

#mkdir -p build
#cd build
#../run_cmake.sh



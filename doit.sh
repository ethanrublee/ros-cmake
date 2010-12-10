#!/bin/sh

rm -f ./ros-cmake.rosinstall
wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

rosinstall -n ri/src ./ros-cmake.rosinstall
cd ri/src

. ./setup.sh
./cmake/convert.py





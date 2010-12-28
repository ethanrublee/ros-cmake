#!/bin/sh

rm -rf scratch

rm -f ros-rosmake.rosinstall
wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-rosmake.rosinstall

rosinstall work-rosmake ros-cmake.rosinstall
cd work-rosmake

. ./setup.sh
rosmake -a






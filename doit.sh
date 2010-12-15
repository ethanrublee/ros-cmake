#!/bin/sh -e

PWD=`pwd`
PTHS=$PWD/ros:$PWD/geometry:$PWD/common:$PWD/ros_comm:$PWD/common_msgs:$PWD/cmake

echo "cmake_minimum_required(VERSION 2.8)" > CMakeLists.txt
echo "include(cmake/main.cmake)" >> CMakeLists.txt


#rm -f ./ros-cmake.rosinstall
#wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

#rosinstall -n ri/src ./ros-cmake.rosinstall
#cd ri/src

#. ./setup.sh
#./cmake/convert.py

./cmake/build_index.py index.pkl $PTHS
./cmake/sanitize_manifest.py index.pkl
./cmake/sanitize_cmakelists.py index.pkl

rm -rf build/
mkdir build/

./cmake/generate_cmakelists.py index.pkl build/


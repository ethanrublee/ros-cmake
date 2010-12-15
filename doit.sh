#!/bin/sh -e

WORK=$(dirname $(dirname $(readlink -f $0)))
echo "WORK=$WORK"
PTHS=$WORK/ros:$WORK/geometry:$WORK/common:$WORK/ros_comm:$WORK/common_msgs

cd $WORK
# chmod 000 ros/core/rosbuild

echo 'message("wtf, no cmakelists here")' >> common/actionlib/test/CMakeLists.txt

echo "cmake_minimum_required(VERSION 2.8)" > CMakeLists.txt
echo "include(cmake/main.cmake)" >> CMakeLists.txt
rm -f $WORK/ros/core/roslisp/manifest.xml
cp $WORK/cmake/rospy.cmake $WORK/ros/core/rospy/cmake
cp $WORK/cmake/roscpp.cmake $WORK/ros/core/roscpp/cmake
rm -f ros/tools/rxgraph/CMakeLists.txt ros/tools/rxtools/CMakeLists.txt

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

cd build
echo
echo
echo
echo
echo
echo CMAKESTART
echo
cmake -DROS_BUILD_SHARED_LIBS=TRUE ..

#!/bin/sh -ex

WORK=$(dirname $(dirname $(readlink -f $0)))
echo "WORK=$WORK"
BUILD=$WORK/build
INDEX=$WORK/index.pkl

rm -f $INDEX
export ROS_PACKAGE_PATH=$WORK/ros:$WORK/ros_comm:$WORK/common:$WORK/common_msgs
# export ROS_PACKAGE_PATH=$WORK/ros:$WORK/geometry:$WORK/common:$WORK/ros_comm:$WORK/common_msgs
cd $WORK
# chmod 000 ros/core/rosbuild

#echo 'message("actionlib has no cmakelists.  hrm.")' > common/actionlib/test/CMakeLists.txt

echo "cmake_minimum_required(VERSION 2.8)" > CMakeLists.txt
echo "include(cmake/main.cmake)" >> CMakeLists.txt
rm -f $WORK/ros_comm/clients/roslisp/manifest.xml

#
# deprecated file
#
rm -rf $WORK/common/actionlib/cmake
rm -rf $WORK/common/actionlib/cmake

# FIXME
rm -f ros/tools/rxgraph/CMakeLists.txt ros/tools/rxtools/CMakeLists.txt

if [ -d $WORK/ros/core/rosbuild ] ; then
    rm -f $WORK/ros/core/rosbuild/manifest.xml
    mv $WORK/ros/core/rosbuild $WORK/ros/core/rosbuild.aside
fi
#rm -f ./ros-cmake.rosinstall
#wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

#rosinstall -n ri/src ./ros-cmake.rosinstall
#cd ri/src

./cmake/build_index.py $INDEX $ROS_PACKAGE_PATH

./cmake/sanitize_manifest.py $INDEX
./cmake/sanitize_cmakelists.py -i $INDEX


rsync -a $WORK/cmake/patches/ $WORK/

rm -rf $BUILD/gen
if [ ! -d $WORK/build ] ; then
    mkdir $WORK/build/
fi
rm -f $BUILD/CMakeCache.txt

./cmake/generate_cmakelists.py $INDEX build/
cd $BUILD

echo CMAKESTART
cmake -DROS_BUILD_SHARED_LIBS=TRUE $WORK/

make VERBOSE=1 


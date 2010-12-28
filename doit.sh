#!/bin/sh -ex

WORK=$(dirname $(dirname $(readlink -f $0)))
echo "WORK=$WORK"
BUILD=$WORK/build
INDEX=$WORK/index.pkl
INSTALL=$WORK/inst

rm -f $INDEX 
export ROS_PACKAGE_PATH=$WORK/ros:$WORK/ros_comm:$WORK/common:$WORK/common_msgs:$WORK/geometry:$WORK/ros_tutorials
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

# FIXME
rm -f ros/tools/rxgraph/CMakeLists.txt ros/tools/rxtools/CMakeLists.txt

if [ -d $WORK/ros/core/rosbuild ] ; then
    rm -rf $WORK/ros/core/rosbuild
fi
if [ -d $WORK/ros/core/mk ] ; then
    rm -rf $WORK/ros/core/mk
fi

#rm -f ./ros-cmake.rosinstall
#wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

#rosinstall -n ri/src ./ros-cmake.rosinstall
#cd ri/src

rsync -a $WORK/cmake/patches/ $WORK/

./cmake/build_index.py $INDEX $ROS_PACKAGE_PATH
./cmake/sanitize_manifest.py $INDEX
./cmake/sanitize_cmakelists.py -i $INDEX

rm -rf $BUILD
rm -rf $INSTALL
if [ ! -d $WORK/build ] ; then
    mkdir $WORK/build/
fi
rm -f $BUILD/CMakeCache.txt

./cmake/generate_cmakelists.py $INDEX build/
cd $BUILD

echo CMAKESTART
cmake -DROS_BUILD_SHARED_LIBS=TRUE -DCMAKE_INSTALL_PREFIX=$INSTALL $WORK/

make -j8
make install


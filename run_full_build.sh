#!/bin/sh -ex

WORK=$(dirname $(dirname $(readlink -f $0)))
echo "WORK=$WORK"
BUILD=$WORK/build
INDEX=$WORK/index.pkl
INSTALL=$WORK/inst

rm -f $INDEX 
export ROS_PACKAGE_PATH=$WORK/rosidl\
:$WORK/ros\
:$WORK/ros_comm\
:$WORK/common\
:$WORK/common_msgs\
:$WORK/geometry\
:$WORK/ros_tutorials\
:$WORK/common_tutorials\
:$WORK/rx\
:$WORK/diagnostics\
:$WORK/driver_common\
:$WORK/perception_pcl\
:$WORK/image_common\
:$WORK/laser_pipeline\
:$WORK/camera_drivers\
:$WORK/robot_model\
:$WORK/visualization\
:$WORK/visualization_common\

$WORK/cmake/vcs_revert_path.sh $ROS_PACKAGE_PATH

cd $WORK

echo "cmake_minimum_required(VERSION 2.8)" > CMakeLists.txt
echo "include(cmake/main.cmake)" >> CMakeLists.txt
rm -f $WORK/ros_comm/clients/roslisp/manifest.xml

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
./cmake/generate_manifest.py -i $INDEX

rsync -a $WORK/cmake/patches/ $WORK/

# rm -rf $BUILD
rm -rf $INSTALL
if [ ! -d $WORK/build ] ; then
    mkdir $WORK/build/
fi
rm -f $BUILD/CMakeCache.txt

#./cmake/generate_cmakelists.py $INDEX build/ ./cmake
./cmake/generate.py $ROS_PACKAGE_PATH ./cmake ./build
cd $BUILD

echo CMAKESTART
cmake -DCMAKE_INSTALL_PREFIX=$INSTALL $WORK/

make
# make VERBOSE=1
make install



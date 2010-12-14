#!/bin/sh -e

PTHS=/ssd/sg/cmake/work/ros:/ssd/wg/cmake/work/geometry:/ssd/wg/cmake/work/common:/ssd/wg/cmake/work/ros_comm:/ssd/wg/cmake/work/cmake

#rm -f ./ros-cmake.rosinstall
#wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

#rosinstall -n ri/src ./ros-cmake.rosinstall
#cd ri/src

#. ./setup.sh
#./cmake/convert.py

./cmake/build_index.py index.pkl $PTHS
./cmake/sanitize_manifest.py index.pkl
./cmake/sanitize_cmakelists.py index.pkl





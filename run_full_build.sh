#!/bin/sh -ex

WORK=$(dirname $(dirname $(readlink -f $0)))
echo "WORK=$WORK"
BUILD=$WORK/build
INDEX=$WORK/index.pkl
INSTALL=$WORK/inst

rm -f $INDEX 
read PKGS <<EOF 
rosidl \
ros \
ros_comm \
common \
common_msgs \
geometry \
ros_tutorials \
common_tutorials \
rx \
diagnostics \
driver_common \
perception_pcl \
image_common \
laser_pipeline \
camera_drivers \
robot_model \
visualization \
visualization_common
EOF

do_rsync () 
{
    echo $PKGS
    for dir in $PKGS
    do
        if [ -d $WORK/$dir -a -d $WORK/cmake/patches/$dir/ ] ; then
            rsync -a $WORK/cmake/patches/$dir/ $WORK/$dir/
        fi
    done
}

ROS_PACKAGE_PATH=""
echo $PKGS
for dir in $PKGS
do
    ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$WORK/$dir
done

echo $ROS_PACKAGE_PATH

$WORK/cmake/vcs_revert_path.sh $ROS_PACKAGE_PATH

cd $WORK

echo "cmake_minimum_required(VERSION 2.8)" > CMakeLists.txt
echo "include(cmake/main.cmake)" >> CMakeLists.txt

do_rsync

./cmake/build_index.py $INDEX $ROS_PACKAGE_PATH
./cmake/sanitize_manifest.py $INDEX
./cmake/sanitize_cmakelists.py -i $INDEX
./cmake/generate_manifest.py -i $INDEX

do_rsync

# rm -rf $BUILD
rm -rf $INSTALL
if [ ! -d $WORK/build ] ; then
    mkdir $WORK/build/
fi
rm -f $BUILD/CMakeCache.txt

#./cmake/generate.py $ROS_PACKAGE_PATH ./cmake ./build
echo "#!/bin/sh" > run_cmake.sh
echo "cmake -DCMAKE_INSTALL_PREFIX=$INSTALL -DROS_PACKAGE_PATH=$ROS_PACKAGE_PATH -DROS_3RDPARTY_PATH=$WORK/3rdparty $WORK/ $*" >> run_cmake.sh
chmod 755 run_cmake.sh

cd $BUILD

echo CMAKESTART
$WORK/run_cmake.sh

make
# make VERBOSE=1
make install



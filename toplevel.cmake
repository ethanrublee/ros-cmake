# 
#  CMakeLists.txt for 'ros' stack 
#
cmake_minimum_required(VERSION 2.6.2)  # this is jaunty's version

#set_property(GLOBAL 
#  PROPERTY
#  GLOBAL_DEPENDS_DEBUG_MODE TRUE
#  )

if("$ENV{ROS_ROOT}" STREQUAL "")
  set(ENV{ROS_ROOT} ${CMAKE_CURRENT_SOURCE_DIR})
endif()
set(ROS_ROOT $ENV{ROS_ROOT})

if (CMAKE_VERBOSE_MAKEFILE)
  set(ROSBUILD_VERBOSE "--verbose=\$\$VERBOSE"  CACHE STRING "verbose args")
  set(ROSBUILD_MINUSV "-v")
endif()

add_custom_target(showenv
  COMMAND /usr/bin/env)



##############################################################################
# First things first: we must have rospack.
##############################################################################
set(ROSPACK_BUILD ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/rospack)
if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/bin/rospack)
  file(MAKE_DIRECTORY ${ROSPACK_BUILD})
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/tools/rospack/build.sh.in
    ${ROSPACK_BUILD}/build.sh)
  execute_process(COMMAND 
    ${ROSPACK_BUILD}/build.sh
    WORKING_DIRECTORY ${ROSPACK_BUILD})
endif()
find_program(ROSPACK_EXE 
  rospack 
  PATHS ${CMAKE_CURRENT_BINARY_DIR}/bin
  $ENV{ROS_ROOT}/bin
  DOC "rospack executable")

if (NOT ROSPACK_EXE)
  message(FATAL_ERROR "Couldn't find rospack. Not bootstrapped correctly?")
else()
  message(STATUS "rospack found at ${ROSPACK_EXE}")
endif()

find_program(ROSSTACK_EXE 
  NAMES rosstack 
  PATHS ${CMAKE_CURRENT_BINARY_DIR}/bin
  DOC "rosstack executable")
if (NOT ROSSTACK_EXE)
  message(FATAL_ERROR "Couldn't find rosstack. Not bootstrapped correctly?")
else()
  message(STATUS "rosstack found at ${ROSSTACK_EXE}")
endif()


link_directories(${CMAKE_CURRENT_BINARY_DIR}/lib)

##############################################################################
#  Generated code directories
##############################################################################


set(ROSBUILD_GEN_DIR ${CMAKE_BINARY_DIR}/gen)
set(ROSBUILD_SRV_DIR NOOOOOOOOOOOOOO_DONT_USE_ME)
set(ROSBUILD_MSG_DIR AUUUUUUUUUUUUUUUUGH_NOT_TO_USE_ME)

include_directories(${ROSBUILD_GEN_DIR}/cpp/srv)
include_directories(${ROSBUILD_GEN_DIR}/cpp/msg)

##############################################################################
# Shell out like this.
##############################################################################
set(ROSLIB_PYPATH ${CMAKE_CURRENT_SOURCE_DIR}/core/roslib/src)
set(ROSBUILD_PYPATH ${CMAKE_CURRENT_SOURCE_DIR}/core/rosbuild/src)

#
# NOTE:  ${ROSBUILD_GEN_DIR}/py MUST COME FIRST as it contains the magic
# import hooks
#
set(ROSBUILD_SUBSHELL
  /usr/bin/env 
  ROS_ROOT=${ROS_ROOT} 
  ROS_BUILD=${CMAKE_CURRENT_BINARY_DIR}
  PATH=${ROS_ROOT}/bin:${CMAKE_CURRENT_BINARY_DIR}/bin:$ENV{PATH}
  PYTHONPATH=${ROSBUILD_GEN_DIR}/py:${ROSLIB_PYPATH}:${ROSBUILD_PYPATH}:$ENV{PYTHONPATH}
  )
set(ROSBUILD_SUBSHELL_ALT ${CMAKE_BINARY_DIR}/setup.sh)

set(ROSBOOST_CFG "${ROS_ROOT}/tools/rosboost_cfg/src/rosboost_cfg/rosboost_cfg.py")


##############################################################################
# Hack:  bootstrap rosboost-cfg
##############################################################################
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
set(ENV{PATH} ${CMAKE_CURRENT_BINARY_DIR}/bin:$ENV{PATH})
if (NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/bin/rosboost-cfg)
  execute_process(COMMAND ln -s ${ROSBOOST_CFG} 
    ${CMAKE_CURRENT_BINARY_DIR}/bin/rosboost-cfg)
endif()

set(ROSBUILD_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/core/rosbuild)

# Policy settings to prevent warnings on 2.6 but ensure proper operation on
# 2.4.
if(COMMAND cmake_policy)
  # Logical target names must be globally unique.
  cmake_policy(SET CMP0002 OLD)
  # Libraries linked via full path no longer produce linker search paths.
  cmake_policy(SET CMP0003 OLD)
  # Preprocessor definition values are now escaped automatically.
  cmake_policy(SET CMP0005 OLD)
  if(POLICY CMP0011)
    # Included scripts do automatic cmake_policy PUSH and POP.
    cmake_policy(SET CMP0011 OLD)
  endif(POLICY CMP0011)
endif(COMMAND cmake_policy)

##############################################################################
#
#  Well the env variable handling is awful, it is true.
#
if("$ENV{ROS_INSTALL_PREFIX}" STREQUAL "")
  set(ROS_INSTALL_PREFIX "/tmp/default-ros-install-prefix")
else()
  set(ROS_INSTALL_PREFIX $ENV{ROS_INSTALL_PREFIX})
endif()
set(CMAKE_INSTALL_PREFIX ${ROS_INSTALL_PREFIX})


# Load private macros (not to be used externally)
include($ENV{ROS_ROOT}/core/rosbuild/private.cmake)
# Load public macros (developer's API)
include($ENV{ROS_ROOT}/core/rosbuild/public.cmake)

set(ROS_VERSION "diamondback-dev")

include(3rdparty/gtest/gtest.cmake)
set(ROSPACK_MAKEDIST true)

# Append to CPACK_SOURCE_IGNORE_FILES a semicolon-separated list of
# directories (or patterns, but directories should suffice) that should 
# be excluded from the distro.  This is not the place to put things that
# should be ignored everywhere, like "build" directories; that happens in
# rosbuild/rosbuild.cmake.  Here should be listed packages that aren't
# ready for inclusion in a distro.
#
# This list is combined with the list in rosbuild/rosbuild.cmake.  Note
# that CMake 2.6 may be required to ensure that the two lists are combined
# properly.  CMake 2.4 seems to have unpredictable scoping rules for such
# variables.
#list(APPEND CPACK_SOURCE_IGNORE_FILES /core/experimental)

rosbuild_make_distribution(1.3.x-trunk)

# message("ROS_INSTALL_PREFIX=${ROS_INSTALL_PREFIX}")

foreach(script 
    rosbag
    rosboost-cfg
    rosclean
    rosconfig
    roscore
    roscreate-pkg
    roscreate-stack
    rosdep
    rosgraph
    roslaunch
    roslaunch-deps
    roslaunch-logs
    roslocate
    rosmake
    rosmaster
    rosmsg
    rosnode
    rosparam
    rosrun
    rosservice
    rossrv
    rostest
    rostopic
    rosversion
    roswtf
    rxbag
    rxconsole
    rxdeps
    rxgraph
    rxloggerlevel
    rxplot)

  rosbuild_install_programs(bin/${script}
    INSTALL_TO_ROOT)

endforeach()

set(ENV{ROS_BUILD} ${CMAKE_CURRENT_BINARY_DIR})

# message("ROSBUILD_SUBSHELL=${ROSBUILD_SUBSHELL}")
execute_process(
  COMMAND
  ${ROSBUILD_SUBSHELL}
  ${ROSBUILD_ROOT}/src/rosbuild/gen_cmake.py
  --ros_build=${CMAKE_CURRENT_BINARY_DIR}
  --outfile=generated.cmake

  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
  RESULT_VARIABLE res)

if(res)
  message(FATAL_ERROR "Unable to generate CMakeLists for package tree, gen_cmake returned ${res}")
endif()

set(ROS_SETUP ${CMAKE_CURRENT_BINARY_DIR}/setup)
set(ROS_MASTER_URI http://localhost:11311)
foreach(setupfile
    setup.sh
    setup.csh
    env.sh
    )
  configure_file(
    ${ROSBUILD_ROOT}/${setupfile}.buildspace.in
    ${CMAKE_CURRENT_BINARY_DIR}/${setupfile}
    @ONLY)
endforeach()

include(${CMAKE_CURRENT_BINARY_DIR}/generated.cmake)
  
install(FILES 
  ${CMAKE_CURRENT_BINARY_DIR}/setup.sh
  DESTINATION ${ROS_INSTALL_PREFIX})

install(DIRECTORY
  $ENV{ROS_ROOT}/tools/rosbash
  DESTINATION ${ROS_INSTALL_PREFIX}/tools)


# Find roslib; roslib_path will be used later
#rosbuild_invoke_rospack("" roslib path find roslib)
set(roslib_path ${ROS_ROOT}/core/roslib)




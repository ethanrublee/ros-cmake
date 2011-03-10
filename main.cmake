message(STATUS "--- main.cmake ---")

configure_file(cmake/generate.py 
  ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/generate.stamp
  )

if (ROS_PACKAGE_PATH)
  set(ROS_PACKAGE_PATH ${ROS_PACKAGE_PATH} CACHE STRING "ros pkg path")
else()
  set(ROS_PACKAGE_PATH $ENV{ROS_PACKAGE_PATH}:$ENV{ROS_ROOT}
    CACHE STRING "Directories to search for packages to build"
    )
endif()

try_run(CLANG CLANG_COMPRESULT
  ${CMAKE_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/cmake/platform/clang.c
  )
if(CLANG)
  message("You're using clang")
endif()

if (ROS_3RDPARTY_PATH)
  message("ROS_3RDPARTY_PATH=${ROS_3RDPARTY_PATH}")
endif()

#
# this shouldn't really be here
#
if (CLANG)
  add_definitions(-DGTEST_USE_OWN_TR1_TUPLE)
endif()

execute_process(COMMAND
  ${CMAKE_SOURCE_DIR}/cmake/generate.py ${ROS_PACKAGE_PATH}
  ${CMAKE_SOURCE_DIR}/cmake
  ${CMAKE_BINARY_DIR})

if (CMAKE_CROSSCOMPILING)
  message("********* cross-compiling for ${CMAKE_SYSTEM_NAME} **********")
endif()
set(ROSBUILD TRUE CACHE INTERNAL "Flag for building under rosbuild2.")

include(cmake/FindPkgConfig.cmake)

option(ROS_BUILD_SHARED_LIBS "build shared libs" ON)
option(ROS_BUILD_STATIC_LIBS "build static libs" OFF)

project(ROS)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set(CPACK_GENERATOR DEB)
set(CPACK_PACKAGE_CONTACT "Your friends at Willow Garage")
set(CPACK_PACKAGE_NAME "ros-unstable-cpacked")
set(CPACK_PACKAGE_VENDOR "Willow Garage")
set(CPACK_PACKAGE_VERSION "dback")
set(CPACK_PACKAGE_VERSION_MAJOR 1)
set(CPACK_PACKAGE_VERSION_MINOR 7)
set(CPACK_PACKAGE_VERSION_PATCH 0)
set(CPACK_DEBIAN_PACKAGE_SECTION unstable)
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Somebody Smart <smartguy@willowgarage.com>")
set(CPACK_PACKAGE_INSTALL_DIRECTORY /opt/ros/dbag)
set(CPACK_SET_DESTDIR ON)
set(CPACK_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})


execute_process(COMMAND dpkg --print-architecture
  OUTPUT_VARIABLE 
  CPACK_DEBIAN_PACKAGE_ARCHITECTURE
  OUTPUT_STRIP_TRAILING_WHITESPACE)

include(CPack)


set(ROS_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/ros)
set(ROS_SETUP ${CMAKE_CURRENT_BINARY_DIR}/setup)
set(ROSBUILD_SUBSHELL ${CMAKE_CURRENT_BINARY_DIR}/env.sh)
if (NOT ROS_MASTER_URI)
  set(ROS_MASTER_URI http://localhost:11311)
endif()

set(ROSBUILD_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/gen)
file(MAKE_DIRECTORY ${ROSBUILD_GEN_DIR})
include_directories(${ROSBUILD_GEN_DIR}/cpp)

#
# FIXME: hack
#
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/common_msgs/actionlib_msgs/cmake/actionbuild.cmake)
  include(${CMAKE_CURRENT_SOURCE_DIR}/common_msgs/actionlib_msgs/cmake/actionbuild.cmake)
else()
  macro(rosbuild_actions)
    message("WARNING:  project ${PROJECT_NAME} contains actions but actionlib is not in the workspace")
  endmacro()
endif()

#
# FIXME: hack
#
if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/driver_common/dynamic_reconfigure/cmake/cfgbuild.cmake)
  include(${CMAKE_CURRENT_SOURCE_DIR}/driver_common/dynamic_reconfigure/cmake/cfgbuild.cmake)
else()
  macro(rosbuild_cfgs)
    message("WARNING:  project ${PROJECT_NAME} contains dynamic reconfigure specs but dynamic_reconfigure is not in the workspace")
  endmacro()
endif()



#
#  apply MACRO to args ARGN
#
macro(apply MACRO)
  set(APPLY_MACRO ${MACRO})
  set(APPLY_ARGS ${ARGN})
  set(_APPLY ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/_apply.cmake)
  configure_file(_apply.cmake.in
    ${_APPLY}
    @ONLY)
  include(${_APPLY})
endmacro()

#set_property(GLOBAL 
#  PROPERTY
#  GLOBAL_DEPENDS_DEBUG_MODE TRUE)
#
# Globally unique targets.  Wtf. 
#
cmake_policy(SET CMP0002 OLD)

include(cmake/FindPkgConfig.cmake)

find_package(Boost 
  COMPONENTS 
  date_time 
  filesystem 
  graph 
  iostreams 
  math_c99 
  math_tr1 
  prg_exec_monitor
  program_options
  python 
  regex
  serialization 
  signals 
  system 
  thread 
  unit_test_framework 
  wave 
  wserialization)

set(CMAKE_THREAD_PREFER_PTHREAD TRUE CACHE BOOL "prefer pthread")

find_package(Threads)

if (CMAKE_CROSSCOMPILING)
  include_directories(${CMAKE_FIND_ROOT_PATH}/usr/include)
endif()

macro(rosbuild_3rdparty PKGNAME DEPFILE)

  if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${DEPFILE})
    configure_file(install.sh.in ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh
      @ONLY)
  
    execute_process(COMMAND ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh
      RESULT_VARIABLE _3rdparty_result)
    if (NOT ${_3rdparty_result} EQUAL "0")
      message(FATAL_ERROR 
	"FAIL: 3rdparty ${PKGNAME} returned ${_3rdparty_result}, not 0 as we'd hoped.")
    else()
      message(STATUS 
	"3rdparty ${PKGNAME} bootstrap returned ${_3rdparty_result}.  Good.")
    endif()
  endif()

endmacro()

add_custom_target(test-results-run)
add_custom_target(tests)
add_custom_target(test-results
  COMMAND echo ${rostest_path}/bin/rostest-results --nodeps ${PROJECT_NAME}
  COMMENT FIXME test-results)
add_custom_target(clean-test-results)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/private.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/public.cmake)

rosbuild_check_for_sse()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/toplevel.static.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/toplevel.static.cmake)

include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.cmake)

foreach(setupfile
    setup.sh
    setup.csh
    env.sh
    )
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${setupfile}.buildspace.in
    ${CMAKE_CURRENT_BINARY_DIR}/${setupfile}
    @ONLY)
endforeach()

foreach(installfile
    setup.sh
    env.sh
    )
  configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/${installfile}.install.in
    ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${installfile}.install
    @ONLY)

  install(PROGRAMS 
    ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${installfile}.install
    DESTINATION bin
    RENAME ${installfile})
endforeach()
  

#
# fixme:  this doesn't belong here
# 
message("*** fixme, install of ros/bin/")
install(DIRECTORY ${CMAKE_SOURCE_DIR}/ros/bin/
  DESTINATION bin/
  FILE_PERMISSIONS 
  WORLD_EXECUTE WORLD_READ GROUP_EXECUTE GROUP_READ OWNER_EXECUTE OWNER_READ
  )
  

install(DIRECTORY ros/config/
  DESTINATION config/
  )
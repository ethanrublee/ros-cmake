message(STATUS "--- main.cmake ---")

set(ROS_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/ros)
set(ROS_SETUP ${CMAKE_CURRENT_BINARY_DIR}/setup)
set(ROSBUILD_SUBSHELL ${CMAKE_CURRENT_BINARY_DIR}/env.sh)
set(ROS_PACKAGE_PATH $ENV{ROS_PACKAGE_PATH}
  CACHE STRING "Directories to search for packages to build"
  )
if (NOT ROS_MASTER_URI)
  set(ROS_MASTER_URI http://localhost:11311)
endif()

set(ROSBUILD_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/gen)
file(MAKE_DIRECTORY ${ROSBUILD_GEN_DIR})
include_directories(${ROSBUILD_GEN_DIR}/cpp)

if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/common_msgs/actionlib_msgs/cmake/actionbuild.cmake)
  include(${CMAKE_CURRENT_SOURCE_DIR}/common_msgs/actionlib_msgs/cmake/actionbuild.cmake)
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


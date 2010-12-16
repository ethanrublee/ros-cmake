message(STATUS "--- main.cmake ---")

set(ROS_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/ros)
set(ROS_SETUP ${CMAKE_CURRENT_BINARY_DIR}/setup)
set(ROSBUILD_SUBSHELL ${CMAKE_CURRENT_BINARY_DIR}/env.sh)
set(ROS_PACKAGE_PATH $ENV{ROS_PACKAGE_PATH})
set(ROSBUILD_GEN_DIR ${CMAKE_CURRENT_BINARY_DIR}/gen)
file(MAKE_DIRECTORY ${ROSBUILD_GEN_DIR})

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
  
    execute_process(COMMAND ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh)
  endif()

endmacro()

add_custom_target(test-results-run)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/private.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/public.cmake)

include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.cmake)

foreach(setupfile
    setup.sh
    setup.csh
    env.sh)
  configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${setupfile}.buildspace.in
    ${CMAKE_CURRENT_BINARY_DIR}/${setupfile}
    @ONLY)
endforeach()



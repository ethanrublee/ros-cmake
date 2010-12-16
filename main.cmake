message(STATUS "--- main.cmake ---")

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






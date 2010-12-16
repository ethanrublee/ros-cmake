message(STATUS "--- main.cmake ---")
cmake_policy(SET CMP0002 OLD)

macro(rosbuild_3rdparty PKGNAME DEPFILE)

  configure_file(install.sh.in ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh
    @ONLY)
  
  execute_process(COMMAND ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh)

endmacro()

add_custom_target(test-results-run)
add_custom_target(3rdparty)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/private.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/public.cmake)

include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.cmake)






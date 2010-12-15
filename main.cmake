message(STATUS "--- main.cmake ---")
cmake_policy(SET CMP0002 OLD)

add_custom_target(test-results-run)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/private.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/public.cmake)

include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.cmake)






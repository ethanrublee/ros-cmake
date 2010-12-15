message(STATUS "--- main.cmake ---")

add_custom_target(rospack_genmsg)
add_custom_target(rospack_gensrv)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/private.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/public.cmake)
include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.cmake)




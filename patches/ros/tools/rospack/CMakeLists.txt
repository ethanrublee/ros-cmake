project(rospack)
include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
include_directories(include ${PROJECT_SOURCE_DIR})

add_definitions(-DTIXML_USE_STL)
set(rospack_sources rospack.cpp
                    tinyxml-2.5.3/tinystr.cpp
                    tinyxml-2.5.3/tinyxml.cpp
                    tinyxml-2.5.3/tinyxmlparser.cpp
                    tinyxml-2.5.3/tinyxmlerror.cpp)
set(rosstack_sources rosstack.cpp)

# Here we duplicate a bit of the logic in rosbuild/public.cmake.
if(NOT ROS_BUILD_STATIC_LIBS AND NOT ROS_BUILD_SHARED_LIBS)
  message(FATAL_ERROR "Neither shared nor static libraries are enabled.  Please set either ROS_BUILD_STATIC_LIBS or ROS_BUILD_SHARED_LIBS to true.")
endif(NOT ROS_BUILD_STATIC_LIBS AND NOT ROS_BUILD_SHARED_LIBS)
if(ROS_BUILD_STATIC_EXES AND ROS_BUILD_SHARED_LIBS)
  message(FATAL_ERROR "Static executables are requested, but so are shared libs. This configuration is unsupported.  Please either set ROS_BUILD_SHARED_LIBS to false or set ROS_BUILD_STATIC_EXES to false.")
endif(ROS_BUILD_STATIC_EXES AND ROS_BUILD_SHARED_LIBS)

if(ROS_BUILD_SHARED_LIBS)
  # If shared libs are being built, they get the default CMake target name
  # No matter what, the libraries get the same name in the end.
  add_library(rospack SHARED ${rospack_sources})
  add_library(rosstack SHARED ${rosstack_sources})

  # Prevent deletion of existing lib of same name
  set_target_properties(rospack PROPERTIES CLEAN_DIRECT_OUTPUT 1)
  set_target_properties(rosstack PROPERTIES CLEAN_DIRECT_OUTPUT 1)
endif(ROS_BUILD_SHARED_LIBS)

if(ROS_BUILD_STATIC_LIBS)
  # If we're only building static libs, then they get the default CMake
  # target name.
  if(NOT ROS_BUILD_SHARED_LIBS)
    set(static_rospack "rospack")
    set(static_rosstack "rosstack")
  else(NOT ROS_BUILD_SHARED_LIBS)
    set(static_rospack "rospack-static")
    set(static_rosstack "rosstack-static")
  endif(NOT ROS_BUILD_SHARED_LIBS)

  add_library(${static_rospack} STATIC ${rospack_sources})
  add_library(${static_rosstack} STATIC ${rosstack_sources})

  # Set output name to be the same as shared lib (may not work on Windows)
  set_target_properties(${static_rospack} PROPERTIES OUTPUT_NAME "rospack")
  set_target_properties(${static_rosstack} PROPERTIES OUTPUT_NAME "rosstack")
  # Also add -fPIC, because CMake leaves it out when building static
  # libs, even though it's necessary on 64-bit machines for linking this
  # lib against shared libs downstream.
  set_target_properties(${static_rospack} PROPERTIES COMPILE_FLAGS "-fPIC")
  set_target_properties(${static_rosstack} PROPERTIES COMPILE_FLAGS "-fPIC")

  # Prevent deletion of existing lib of same name
  set_target_properties(${static_rospack} PROPERTIES CLEAN_DIRECT_OUTPUT 1)
  set_target_properties(${static_rosstack} PROPERTIES CLEAN_DIRECT_OUTPUT 1)
endif(ROS_BUILD_STATIC_LIBS)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR}/bin)

add_executable(rospackexe main.cpp)
set_target_properties(rospackexe PROPERTIES OUTPUT_NAME rospack)
target_link_libraries(rosstack rospack)
add_executable(rosstackexe rosstack_main.cpp)
set_target_properties(rosstackexe PROPERTIES OUTPUT_NAME rosstack)

target_link_libraries(rospackexe rospack)
target_link_libraries(rosstackexe rosstack rospack)

if(ROS_BUILD_STATIC_EXES AND ${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
  # This will probably only work on Linux.  The LINK_SEARCH_END_STATIC
  # property should be sufficient, but it doesn't appear to work
  # properly.
  set_target_properties(rospackexe PROPERTIES
                        LINK_FLAGS "-static-libgcc -Wl,-Bstatic")
  set_target_properties(rosstackexe PROPERTIES
                        LINK_FLAGS "-static-libgcc -Wl,-Bstatic")
endif(ROS_BUILD_STATIC_EXES AND ${CMAKE_SYSTEM_NAME} STREQUAL "Linux")

install(TARGETS rospack rosstack rospackexe rosstackexe
  EXPORT ROS
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib)

install(FILES include/rospack/rospack.h
        DESTINATION include/rospack)

# Prevent warnings about duplicate definition of the targets mentioned
# below
if(COMMAND cmake_policy)
  # Logical target names must be globally unique.
  cmake_policy(SET CMP0002 OLD)
endif(COMMAND cmake_policy)
# These targets might be called by rosmakeall
add_custom_target(test)
add_custom_target(tests)
add_custom_target(test-results)
add_custom_target(test-future)
add_custom_target(gcoverage)

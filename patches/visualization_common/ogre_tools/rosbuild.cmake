if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
  include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
endif()
# FindPkgConfig was introduced after 2.4.6, so we provide a copy of it
#include(FindPkgConfig)
#set(ROS_BUILD_TYPE Debug)
rosbuild_add_boost_directories()
#set(EXECUTABLE_OUTPUT_PATH ${PROJECT_SOURCE_DIR}/bin)
find_package(wxWidgets REQUIRED)
include(${wxWidgets_USE_FILE})
include_directories(${wxWidgets_INCLUDE_DIRS})

if(NOT wxWidgets_FOUND)
  message("wxWidgetsnotfound!Aborting...")
  fail()
endif(NOT wxWidgets_FOUND)

find_package(PythonLibs REQUIRED)

include_directories(${PYTHON_INCLUDE_PATH})
# We need GTK2 and OpenGL for the wx render window
pkg_check_modules(GTK2 gtk+-2.0)
include_directories(${GTK2_INCLUDE_DIRS})
add_definitions(${GTK2_DEFINITIONS})
link_directories(${GTK2_LIBRARY_DIRS})
find_package(OpenGL REQUIRED)
include_directories(${OPENGL_INCLUDE_DIR})
# Find the combined swig flags for this project
rosbuild_invoke_rospack(${PROJECT_NAME} ${PROJECT_NAME} SWIG_FLAGS "export" "--lang=swig" "--attrib=flags")
set(SWIG_FLAGS ${${PROJECT_NAME}_SWIG_FLAGS})
# Find the wxswig executable
# Add a custom command for generating the swig output files
set(SWIG_INTERFACE_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/ogre_tools/ogre_tools.i)
set(SWIG_OUTPUT_PYTHON_FILE ${PROJECT_BINARY_DIR}/ogre_tools.py)

set(SWIG_OUTPUT_CPP_FILE 
  ${PROJECT_BINARY_DIR}/ogre_tools_swig_generated.cpp)

set(SWIG_COMMAND 
  ${WXSWIG_EXECUTABLE} ${SWIG_FLAGS} -o ${SWIG_OUTPUT_CPP_FILE} -outdir ../lib -module ${PROJECT_NAME} ${SWIG_INTERFACE_FILE})

set_source_files_properties(${SWIG_OUTPUT_CPP_FILE} PROPERTIES GENERATED true)

add_custom_command(OUTPUT 
  ${SWIG_OUTPUT_CPP_FILE} 
  COMMAND ${SWIG_COMMAND} 
  DEPENDS ${SWIG_INTERFACE_FILE} 
  ${CMAKE_CURRENT_SOURCE_DIR}/src/ogre_tools/initialization.i 
  ${CMAKE_CURRENT_SOURCE_DIR}/src/ogre_tools/initialization.h
  COMMENT "Generating ${SWIG_OUTPUT_CPP_FILE} ${SWIG_OUTPUT_PYTHON_FILE}")

# We add src/ogre_tools to the include list so that
# ogre_tools_swig_generated.cpp can find its headers.  This is part of a
# workaround for a deficiency in CMake 2.4's handling of generated sources.
include_directories(${PROJECT_SOURCE_DIR}/src/ogre_tools)
# We make one library with the basic C++ code...

rosbuild_add_library(${PROJECT_NAME} 
  src/ogre_tools/initialization.cpp 
  src/ogre_tools/point_cloud.cpp 
  src/ogre_tools/object.cpp 
  src/ogre_tools/shape.cpp 
  src/ogre_tools/grid.cpp 
  src/ogre_tools/arrow.cpp 
  src/ogre_tools/axes.cpp 
  src/ogre_tools/billboard_line.cpp 
  src/ogre_tools/camera_base.cpp 
  src/ogre_tools/fps_camera.cpp 
  src/ogre_tools/orbit_camera.cpp 
  src/ogre_tools/ortho_camera.cpp 
  src/ogre_tools/movable_text.cpp 
  src/ogre_tools/wx_ogre_render_window.cpp 
  src/ogre_tools/orthographic.cpp 
  src/ogre_tools/stl_loader.cpp)

# make sure we set the gl and glu libraries only if they are avilable
set(OGRE_TOOLS_GL_LIBS "")
if(OPENGL_gl_LIBRARY)
  set(OGRE_TOOLS_GL_LIBS ${OGRE_TOOLS_GL_LIBS} ${OPENGL_gl_LIBRARY})
endif(OPENGL_gl_LIBRARY)
if(OPENGL_glu_LIBRARY)
  set(OGRE_TOOLS_GL_LIBS ${OGRE_TOOLS_GL_LIBS} ${OPENGL_glu_LIBRARY})
endif(OPENGL_glu_LIBRARY)
set(X11_LIBS "")
if(UNIX AND NOT APPLE)
  include(FindX11)
  if(NOT X11_FOUND)
    message(send_error "X11notfound")
  endif(NOT X11_FOUND)
  set(X11_LIBS ${X11_LIBRARIES})
endif(UNIX AND NOT APPLE)
target_link_libraries(${PROJECT_NAME} ${wxWidgets_LIBRARIES} ${GTK2_LIBRARIES} ${OGRE_TOOLS_GL_LIBS} ${OGRE_LIBRARIES} ${X11_LIBS})
# ...and we make another library with just the SWIG wrappers, linked
# against the C++ lib.
rosbuild_add_library(python_${PROJECT_NAME} ${SWIG_OUTPUT_CPP_FILE})
target_link_libraries(python_${PROJECT_NAME} ${PROJECT_NAME} ${PYTHON_LIBRARIES})
# swig python needs a shared library named _<modulename>.[so|dll|...]
# this renames the output file to conform to that by prepending an underscore and removing the "lib" prefix
set_target_properties(python_${PROJECT_NAME} PROPERTIES OUTPUT_NAME _${PROJECT_NAME} PREFIX "")
rosbuild_add_executable(grid_test EXCLUDE_FROM_ALL src/test/grid_test.cpp)
target_link_libraries(grid_test ${PROJECT_NAME} ${wxWidgets_LIBRARIES})
rosbuild_declare_test(bin/grid_test)
include_directories(src)
rosbuild_add_executable(stl_to_mesh src/stl_to_mesh/stl_to_mesh.cpp)
target_link_libraries(stl_to_mesh ${OGRE_LIBRARIES} ${PROJECT_NAME})
rosbuild_link_boost(stl_to_mesh filesystem system)
#rosbuild_add_gtest_future(test/utest test/utest.cpp)
#target_link_libraries(test/utest ${PROJECT_NAME})


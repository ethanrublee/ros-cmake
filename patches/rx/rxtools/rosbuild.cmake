if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
  include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
endif()
rosbuild_add_boost_directories()
find_package(wxWidgets REQUIRED)
if(NOT wxWidgets_FOUND)
  message(FATAL_ERROR "wxWidgetsnotfound!Aborting...")
endif(NOT wxWidgets_FOUND)
include(${wxWidgets_USE_FILE})
include_directories(${wxWidgets_INCLUDE_DIRS})
find_package(PythonLibs REQUIRED)
include_directories(${PYTHON_INCLUDE_PATH})
include_directories(${PROJECT_SOURCE_DIR}/src)
# shared library (for C++)
rosbuild_add_library(${PROJECT_NAME} src/rxtools/topic_display.cpp src/rxtools/topic_display_generated.cpp src/rxtools/topic_display_dialog.cpp src/rxtools/rosout_generated.cpp src/rxtools/rosout_panel.cpp src/rxtools/rosout_filter.cpp src/rxtools/rosout_text_filter.cpp src/rxtools/rosout_text_filter_control.cpp src/rxtools/rosout_severity_filter.cpp src/rxtools/rosout_severity_filter_control.cpp src/rxtools/rosout_list_control.cpp src/rxtools/rosout_setup_dialog.cpp src/rxtools/logger_level_panel.cpp src/rxtools/init_roscpp.cpp)
target_link_libraries(${PROJECT_NAME} ${wxWidgets_LIBRARIES})
rosbuild_link_boost(${PROJECT_NAME} thread regex)
# Find the combined swig flags for this project
rosbuild_invoke_rospack(${PROJECT_NAME} ${PROJECT_NAME} SWIG_FLAGS "export" "--lang=swig" "--attrib=flags")
set(SWIG_FLAGS ${${PROJECT_NAME}_SWIG_FLAGS})
# Find the wxswig executable
# Add a custom command for generating the swig output files
set(SWIG_INTERFACE_FILE ${PROJECT_SOURCE_DIR}/src/rxtools/rxtools.i)
set(SWIG_OUTPUT_PYTHON_FILE ${PROJECT_SOURCE_DIR}/lib/rxtoolscpp.py)

set(SWIG_OUTPUT_CPP_FILE ${PROJECT_BINARY_DIR}/rosout_panel_swig_generated.cpp)

file(MAKE_DIRECTORY ${PROJECT_BINARY_DIR}/lib)

set(SWIG_COMMAND ${WXSWIG_EXECUTABLE} ${SWIG_FLAGS} 
  -o ${SWIG_OUTPUT_CPP_FILE} -outdir ${PROJECT_BINARY_DIR}/lib 
  -module rxtoolscpp ${SWIG_INTERFACE_FILE})

set_source_files_properties(${SWIG_OUTPUT_CPP_FILE} PROPERTIES GENERATED true)

add_custom_command(OUTPUT ${SWIG_OUTPUT_CPP_FILE} 
  COMMAND ${SWIG_COMMAND} 
  DEPENDS ${SWIG_INTERFACE_FILE} 
  ${CMAKE_CURRENT_SOURCE_DIR}/src/rxtools/rosout_generated.h 
  ${CMAKE_CURRENT_SOURCE_DIR}/src/rxtools/rosout_panel.h 
  ${CMAKE_CURRENT_SOURCE_DIR}/src/rxtools/init_roscpp.h)
# We add src/wx_rosout to the include list so that
# ogre_tools_swig_generated.cpp can find its headers.  This is part of a
# workaround for a deficiency in CMake 2.4's handling of generated sources.
include_directories(${PROJECT_SOURCE_DIR}/src/rxtools)
# shared library (with SWIG)
rosbuild_add_swigpy_library(python_${PROJECT_NAME} ${PROJECT_NAME}cpp ${SWIG_OUTPUT_CPP_FILE})
target_link_libraries(python_${PROJECT_NAME} ${PROJECT_NAME} ${PYTHON_LIBRARIES})
#rxconsole binary
rosbuild_add_executable(rxconsole src/rxconsole/rxconsole.cpp)
target_link_libraries(rxconsole ${PROJECT_NAME})
#rxloggerlevel binary
rosbuild_add_executable(rxloggerlevel src/rxloggerlevel/rxloggerlevel.cpp)
target_link_libraries(rxloggerlevel ${PROJECT_NAME})


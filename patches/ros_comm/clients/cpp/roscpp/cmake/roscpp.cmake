set(genmsg_cpp_exe ${CMAKE_SOURCE_DIR}/ros_comm/clients/cpp/roscpp/scripts/genmsg_cpp.py)
# Message-generation support.
macro(genmsg_cpp TYPE)

  foreach(_msg ${ARGN})
    # Construct the path to the .msg file
    if (${TYPE} STREQUAL "STATIC")
      set(_input ${PROJECT_SOURCE_DIR}/${_msg})
      rosbuild_assert_file_exists(${_input})
    elseif(${TYPE} STREQUAL "GENERATED")
      set(_input ${_msg})
    else()
      message(FATAL_ERROR "Unknown message type \"${TYPE}\" (must be either STATIC or GENERATED)")
    endif()

    get_filename_component(_fname ${_msg} NAME)

    string(REPLACE ".msg" ".h" _output_cpp_base ${_fname})

    set(_outdir ${ROSBUILD_GEN_DIR}/cpp/msg)
    set(_output_cpp ${_outdir}/${PROJECT_NAME}/${_output_cpp_base})

    list(APPEND ${PROJECT_NAME}_generated ${_output_cpp})

    set(_incflags "")
    foreach(dir ${DEPENDED_PACKAGE_PATHS})
      list(APPEND _incflags -I${dir})
    endforeach()

    # Add the rule to build the .h the .msg
    add_custom_command(
      OUTPUT ${_output_cpp} 
      COMMAND ${ROSBUILD_SUBSHELL} 
      ${genmsg_cpp_exe} 
      ${_input}
      -p ${PROJECT_NAME}
      -o ${_outdir}
      -I${CMAKE_CURRENT_BINARY_DIR} ${_incflags} -I${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${_input} ${genmsg_cpp_exe} ${gendeps_exe}
      COMMENT "Generating C++ message from ${_input}"
      )
  endforeach(_msg)

endmacro(genmsg_cpp)


set(gensrv_cpp_exe ${CMAKE_SOURCE_DIR}/ros_comm/clients/cpp/roscpp/scripts/gensrv_cpp.py)
# Service-generation support.
macro(gensrv_cpp TYPE)

  foreach(_srv ${ARGN})
    # Construct the path to the .srv file

    # Construct the path to the .msg file
    if (${TYPE} STREQUAL "STATIC")
      set(_input ${PROJECT_SOURCE_DIR}/${_srv})
    elseif(${TYPE} STREQUAL "GENERATED")
      set(_input ${CMAKE_CURRENT_BINARY_DIR}/${_srv})
    else()
      message(FATAL_ERROR "Unknown message type \"${TYPE}\" (must be either STATIC or GENERATED)")
    endif()

    get_filename_component(_fname ${_srv} NAME)
    string(REPLACE ".srv" ".h" _output_cpp_base ${_fname})

    set(_outdir ${ROSBUILD_GEN_DIR}/cpp/srv)
    set(_output_cpp ${_outdir}/${PROJECT_NAME}/${_output_cpp_base})
    
    list(APPEND ${PROJECT_NAME}_generated ${_output_cpp})

    set(_incflags "")
    foreach(dir ${DEPENDED_PACKAGE_PATHS})
      list(APPEND _incflags -I${dir})
    endforeach()

    # Add the rule to build the .h from the .srv
    add_custom_command(
      OUTPUT ${_output_cpp} 
      COMMAND ${ROSBUILD_SUBSHELL} 
      ${gensrv_cpp_exe} 
      ${_input}
      -p ${PROJECT_NAME}
      -o ${_outdir}
      ${_incflags} -I${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${_input} ${gensrv_cpp_exe} ${genmsg_cpp_exe} ${gendeps_exe} 
      COMMENT "Generating C++ service from ${_input}"
      )

  endforeach(_srv)

endmacro(gensrv_cpp)

macro(gentargets_cpp)
  add_custom_target(${PROJECT_NAME}_gen_cpp
    DEPENDS ${${PROJECT_NAME}_generated})
endmacro()
set(genmsg_cpp_exe ${CMAKE_SOURCE_DIR}/ros/core/roscpp/scripts/genmsg_cpp.py)
# Message-generation support.
macro(genmsg_cpp)

  foreach(_msg ${ARGN})
    # Construct the path to the .msg file
    set(_input ${PROJECT_SOURCE_DIR}/${_msg})
  
    rosbuild_assert_file_exists(${_input})
    # rosbuild_gendeps(${PROJECT_NAME} ${_msg})
  
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
      ${_incflags} -I${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${_input} ${genmsg_cpp_exe} ${gendeps_exe}
      )
    message("generated msg: ${_output_cpp}")
  endforeach(_msg)

endmacro(genmsg_cpp)


set(gensrv_cpp_exe ${CMAKE_SOURCE_DIR}/ros/core/roscpp/scripts/gensrv_cpp.py)
# Service-generation support.
macro(gensrv_cpp)

  foreach(_srv ${ARGN})
    # Construct the path to the .srv file

    set(_input ${PROJECT_SOURCE_DIR}/${_srv})
    
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
      )

  endforeach(_srv)

endmacro(gensrv_cpp)

macro(gentargets_cpp)
  add_custom_target(${PROJECT_NAME}_gen_cpp
    DEPENDS ${${PROJECT_NAME}_generated})
endmacro()
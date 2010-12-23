set(genmsg_py_exe ${rospy_PACKAGE_PATH}/scripts/genmsg_py.py)

# Message-generation support.
macro(genmsg_py TYPE)
  set(_inlist "")
  set(_autogen "")

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

    string(REPLACE ".msg" ".py" _output_py_base ${_fname})

    set(_outdir ${ROSBUILD_GEN_DIR}/py/${PROJECT_NAME}/msg)
    set(_output_py ${_outdir}/${_output_py_base})
    file(MAKE_DIRECTORY ${_outdir})
    list(APPEND ${PROJECT_NAME}_generated ${_output_py})

    set(_incflags "")
    foreach(dir ${DEPENDED_PACKAGE_PATHS})
      list(APPEND _incflags -I${dir})
    endforeach()

    # Add the rule to build the .py from the .msg.
    add_custom_command(OUTPUT ${_output_py} 
      COMMAND ${ROSBUILD_SUBSHELL}
      ${genmsg_py_exe} 
      ${_input}
      -o ${_outdir}
      -p ${PROJECT_NAME}
      -I${CMAKE_CURRENT_BINARY_DIR} ${_incflags} -I${CMAKE_CURRENT_SOURCE_DIR}
      DEPENDS ${_input} ${genmsg_py_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_msg}_GENDEPS} ${ROS_MANIFEST_LIST})
    list(APPEND _autogen ${_output_py})
  endforeach(_msg)

  if(_autogen)
    # Set up to create the __init__.py file that will import the .py
    # files created by the above loop.  It can't run until those files are
    # generated, so it depends on them.
    if (False)
      set(_output_py ${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}/msg/__init__.py)
      add_custom_command(OUTPUT ${_output_py}
        COMMAND ${genmsg_py_exe} --initpy ${_inlist}
        DEPENDS ${_autogen})
    endif()
    # Make our target depend on rosbuild_premsgsrvgen, to allow any
    # pre-msg/srv generation steps to be done first.
    # add_dependencies(ROSBUILD_genmsg_py rosbuild_premsgsrvgen)
    # Add our target to the top-level genmsg target, which will be fired if
    # the user calls genmsg()
    # add_dependencies(rospack_genmsg ROSBUILD_genmsg_py)
  endif(_autogen)
endmacro()




set(gensrv_py_exe ${rospy_PACKAGE_PATH}/scripts/gensrv_py.py)
# Service-generation support.
macro(gensrv_py)
  if(False)
    set(_inlist "")
    set(_autogen "")

    foreach(_srv ${ARGN})
      # Construct the path to the .srv file
      set(_input ${PROJECT_SOURCE_DIR}/srv/${_srv})
      # Append it to a list, which we'll pass back to gensrv below
      list(APPEND _inlist ${_input})
      
      rosbuild_gendeps(${PROJECT_NAME} ${_srv})
      

      set(_output_py ${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}/srv/_${_srv})
      string(REPLACE ".srv" ".py" _output_py ${_output_py})
      
      # Add the rule to build the .py from the .srv
      add_custom_command(OUTPUT ${_output_py} 
        COMMAND ${gensrv_py_exe} --noinitpy ${_input}
        DEPENDS ${_input} ${gensrv_py_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_srv}_GENDEPS} ${ROS_MANIFEST_LIST})
      list(APPEND _autogen ${_output_py})
    endforeach(_srv)

    if(_autogen)
      # Set up to create the __init__.py file that will import the .py
      # files created by the above loop.  It can't run until those files are
      # generated, so it depends on them.
      set(_output_py ${PROJECT_SOURCE_DIR}/src/${PROJECT_NAME}/srv/__init__.py)
      add_custom_command(OUTPUT ${_output_py}
        COMMAND ${gensrv_py_exe} --initpy ${_inlist}
        DEPENDS ${_autogen})
      
      # Make our target depend on rosbuild_premsgsrvgen, to allow any
      # pre-msg/srv generation steps to be done first.
      add_dependencies(ROSBUILD_gensrv_py rosbuild_premsgsrvgen)
      # Add our target to the top-level gensrv target, which will be fired if
      # the user calls gensrv()
      add_dependencies(rospack_gensrv ROSBUILD_gensrv_py)
    endif(_autogen)
  endif()
endmacro(gensrv_py)

# Call the macro we just defined.
gensrv_py()

macro(gentargets_py)
endmacro()
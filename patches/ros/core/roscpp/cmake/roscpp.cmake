# rosbuild_find_ros_package(genmsg_cpp)
# rosbuild_find_ros_package(roscpp)
set(roscpp_PACKAGE_PATH ${CMAKE_SOURCE_DIRECTORY}/ros/core/roscpp)
# Message-generation support.
macro(genmsg_cpp)

if (False)
  rosbuild_get_msgs(_msglist)
  set(_autogen "")
  foreach(_msg ${_msglist})
    # Construct the path to the .msg file
    set(_input ${PROJECT_SOURCE_DIR}/msg/${_msg})
  
    rosbuild_gendeps(${PROJECT_NAME} ${_msg})
  
    set(genmsg_cpp_exe ${roscpp_PACKAGE_PATH}/scripts/genmsg_cpp.py)

    set(_output_cpp ${PROJECT_SOURCE_DIR}/msg_gen/cpp/include/${PROJECT_NAME}/${_msg})
    string(REPLACE ".msg" ".h" _output_cpp ${_output_cpp})
  
    # Add the rule to build the .h the .msg
    add_custom_command(OUTPUT ${_output_cpp} 
                       COMMAND ${genmsg_cpp_exe} ${_input}
                       DEPENDS ${_input} ${genmsg_cpp_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_msg}_GENDEPS} ${ROS_MANIFEST_LIST})
    list(APPEND _autogen ${_output_cpp})
  endforeach(_msg)

  # Make our target depend on rosbuild_premsgsrvgen, to allow any
  # pre-msg/srv generation steps to be done first.
  add_dependencies(ROSBUILD_genmsg_cpp rosbuild_premsgsrvgen)
  # Add our target to the top-level rospack_genmsg target, which will be
  # fired if the user calls genmsg()
  add_dependencies(rospack_genmsg ROSBUILD_genmsg_cpp)
else()
  message("genmsg_cpp ${ARGV}")
endif()
endmacro(genmsg_cpp)

# Call the macro we just defined.
genmsg_cpp()

# Service-generation support.
macro(gensrv_cpp)
  if (False)
    rosbuild_get_srvs(_srvlist)
    set(_autogen "")
    foreach(_srv ${_srvlist})
      # Construct the path to the .srv file
      set(_input ${PROJECT_SOURCE_DIR}/srv/${_srv})
      
      rosbuild_gendeps(${PROJECT_NAME} ${_srv})
      
      set(gensrv_cpp_exe ${roscpp_PACKAGE_PATH}/scripts/gensrv_cpp.py)
      set(genmsg_cpp_exe ${roscpp_PACKAGE_PATH}/scripts/genmsg_cpp.py)

      set(_output_cpp ${PROJECT_SOURCE_DIR}/srv_gen/cpp/include/${PROJECT_NAME}/${_srv})
      string(REPLACE ".srv" ".h" _output_cpp ${_output_cpp})
      
      # Add the rule to build the .h from the .srv
      add_custom_command(OUTPUT ${_output_cpp} 
        COMMAND ${gensrv_cpp_exe} ${_input}
        DEPENDS ${_input} ${gensrv_cpp_exe} ${genmsg_cpp_exe} ${gendeps_exe} ${${PROJECT_NAME}_${_srv}_GENDEPS} ${ROS_MANIFEST_LIST})
      list(APPEND _autogen ${_output_cpp})
    endforeach(_srv)

    # Make our target depend on rosbuild_premsgsrvgen, to allow any
    # pre-msg/srv generation steps to be done first.
    add_dependencies(ROSBUILD_gensrv_cpp rosbuild_premsgsrvgen)
    # Add our target to the top-level gensrv target, which will be fired if
    # the user calls gensrv()
    add_dependencies(rospack_gensrv ROSBUILD_gensrv_cpp)
  else()
    message("gensrv_cpp ${ARGV}")
  endif()
endmacro(gensrv_cpp)

# Call the macro we just defined.
gensrv_cpp()

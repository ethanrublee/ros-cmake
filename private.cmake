###############################################################################
# Internal macros below

macro(_rosbuild_warn)
  message("[rosbuild] WARNING: " ${ARGV})
endmacro(_rosbuild_warn)

macro(_rosbuild_warn_deprecate_rospack_prefix name)
  string(REPLACE rospack rosbuild new_name ${name})
  message("[rosbuild] WARNING: ${name} is deprecated; please use ${new_name} instead")
endmacro(_rosbuild_warn_deprecate_rospack_prefix)

macro(_rosbuild_warn_deprecate_no_prefix name)
  message("[rosbuild] WARNING: ${name} is deprecated; please use rosbuild_${name} instead")
endmacro(_rosbuild_warn_deprecate_no_prefix)


###############################################################################
# Macro to turn a list into a string (why doesn't CMake have this
# built-in?)
macro(_rosbuild_list_to_string _string _list)
    set(${_string})
    foreach(_item ${_list})
        string(LENGTH "${${_string}}" _len)
        if(${_len} GREATER 0)
          set(${_string} "${${_string}} ${_item}")
        else(${_len} GREATER 0)
          set(${_string} "${_item}")
        endif(${_len} GREATER 0)
    endforeach(_item)
endmacro(_rosbuild_list_to_string)

###############################################################################
# Macro to dequote a string, in order to properly construct a command line.
# There must be an easier way to do this.
macro(_rosbuild_dequote_string _out _in)
  set(${_out})
  string(REGEX REPLACE " " ";" tmp "${_in}")
  foreach(_item ${tmp})
    string(LENGTH "${${_out}}" _len)
    if(${_len} GREATER 0)
      set(${_out} ${${_out}} ${_item})
    else(${_len} GREATER 0)
      set(${_out} ${_item})
    endif(${_len} GREATER 0)
  endforeach(_item)
endmacro(_rosbuild_dequote_string)


# list(FIND) was introduced after cmake 2.4.6, so we write our own
macro(_rosbuild_list_find _list _item _idx)
    set(${_idx} -1)
    list(LENGTH ${_list} _len)
    math(EXPR _total "${_len} - 1")
    foreach(_i RANGE ${_total})
      list(GET ${_list} ${_i} _it)
      if(_it STREQUAL ${_item})
        set(${_idx} ${_i})
      endif(_it STREQUAL ${_item})
    endforeach(_i)
endmacro(_rosbuild_list_find)

# list(REMOVE_DUPLICATES) was introduced in cmake 2.6, so we write our own
macro(_rosbuild_list_remove_duplicates _inlist _outlist)
  foreach(_item ${_inlist})
    #list(FIND ${_outlist} ${_item} _idx)
    _rosbuild_list_find(${_outlist} ${_item} _idx)
    if(${_idx} EQUAL -1)
      list(APPEND ${_outlist} ${_item})
    endif(${_idx} EQUAL -1)
  endforeach(_item)
endmacro(_rosbuild_list_remove_duplicates)

# Check validity of PYTHONPATH, to avoid esoteric build errors, #954.
# macro(_rosbuild_check_pythonpath)
#   if("$ENV{PYTHONPATH}" STREQUAL "")
#     message("WARNING: PYTHONPATH is not set.  This is almost certainly wrong. Check the ROS installation instructions for details on setting PYTHONPATH.")
#   else("$ENV{PYTHONPATH}" STREQUAL "")
#     if(NOT "$ENV{PYTHONPATH}" MATCHES ".*roslib.*")
#       message("WARNING: PYTHONPATH does not appear to contain roslib.  This is almost certainly wrong. Check the ROS installation instructions for details on setting PYTHONPATH.")
#     endif(NOT "$ENV{PYTHONPATH}" MATCHES ".*roslib.*")
#   endif("$ENV{PYTHONPATH}" STREQUAL "")
# endmacro(_rosbuild_check_pythonpath)

# Check validity of manifest.xml, to avoid esoteric build errors
macro(_rosbuild_check_manifest)
  execute_process(
    COMMAND ${ROSBUILD_SUBSHELL} 
    python -c "import roslib.manifest; roslib.manifest.parse_file('manifest.xml')"
    OUTPUT_VARIABLE _manifest_error
    ERROR_VARIABLE _manifest_error
    RESULT_VARIABLE _manifest_failed
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(_manifest_failed)
    message("[rosbuild] Error from syntax check of ${PROJECT_NAME}/manifest.xml")
    message("${_manifest_error}")
    message(FATAL_ERROR "[rosbuild] Syntax check of ${PROJECT_NAME}/manifest.xml failed; aborting")
  endif(_manifest_failed)


endmacro(_rosbuild_check_manifest)

# Check that the directory where we're building is also where rospack
# thinks that the package lives, to avoid esoteric build errors.
macro(_rosbuild_check_package_location)
  # Ask rospack where our package is
  # message("_rosbuild_check_package_location=${PROJECT_NAME}")
  rosbuild_find_ros_package(${PROJECT_NAME})
  # Compare to where we are
  execute_process(
    COMMAND ${ROSBUILD_SUBSHELL}
    $ENV{ROS_ROOT}/core/rosbuild/bin/check_same_directories.py ${${PROJECT_NAME}_PACKAGE_PATH} ${PROJECT_SOURCE_DIR}
    OUTPUT_VARIABLE _rosbuild_check_package_location_error
    ERROR_VARIABLE _rosbuild_check_package_location_error
    RESULT_VARIABLE _rosbuild_check_package_location_failed
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
# message(">>>>> ${_rosbuild_check_package_location_error}")
  if(_rosbuild_check_package_location_failed)
    message(FATAL_ERROR "[rosbuild] rospack found package \"${PROJECT_NAME}\" at \"${${PROJECT_NAME}_PACKAGE_PATH}\", but the current directory is \"${PROJECT_SOURCE_DIR}\".  You should double-check your ROS_PACKAGE_PATH to ensure that packages are found in the correct precedence order.")
  endif(_rosbuild_check_package_location_failed)
endmacro(_rosbuild_check_package_location)

# helper function to register check that results were generated (#580)
macro(_rosbuild_check_rostest_xml_result test_name test_file)
  add_custom_target(${test_name}_result
                    COMMAND ${rostest_path}/bin/rostest-check-results ${test_file}
		    VERBATIM)
  add_dependencies(test-results-run ${test_name}_result)	 
endmacro(_rosbuild_check_rostest_xml_result test_name)

macro(_rosbuild_add_gtest exe)
  # message(_rosbuild_add_gtest ${exe} ${ARGN})
  # Look for optional TIMEOUT argument, #2645
  parse_arguments(_gtest "TIMEOUT" "" ${ARGN})
  if(NOT _gtest_TIMEOUT)
    set(_gtest_TIMEOUT 60.0)
  endif(NOT _gtest_TIMEOUT)

  # Create the program, with basic + gtest build flags
  rosbuild_add_executable(${exe}
    ${_gtest_DEFAULT_ARGS}
    )
  set_target_properties(${exe} 
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/bin/test
    )
  rosbuild_add_gtest_build_flags(${exe})

  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname ${exe})


  add_custom_target(test_${_testname}
    COMMAND ${ROSBUILD_SUBSHELL} rostest --bare --bare-name=${_testname} --bare-limit=${_gtest_TIMEOUT} ${PROJECT_BINARY_DIR}/bin/test/${exe}
    DEPENDS ${exe}
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    VERBATIM)

  file(APPEND ${CMAKE_CURRENT_BINARY_DIR}/rostest.list
    "rostest --bare --bare-name=${_testname} --bare-limit=${_gtest_TIMEOUT} ${PROJECT_BINARY_DIR}/bin/test/${exe}\n"
    )

  # Don't register to check xml output here, because we may have gotten
  # here through registration of a future test.  Eventually, we should pass
  # in the overriding target (e.g., test-results vs. test-future-results).
  # For now, we call _rosbuild_check_rostest_xml_result() in rosbuild_add_gtest() instead.
  #_rosbuild_check_rostest_xml_result(test_${_testname} ${rosbuild_test_results_dir}/${PROJECT_NAME}/${_testname}.xml)

  # Make sure that any messages get generated prior to building this target
  add_dependencies(${exe} rospack_genmsg)
  add_dependencies(${exe} rospack_gensrv)

  # Make sure all test programs are built before running this test
  # but not if rosbuild_test_nobuild is set, #3008
  if(NOT rosbuild_test_nobuild)
    add_dependencies(test_${_testname} tests)
  endif(NOT rosbuild_test_nobuild)

endmacro(_rosbuild_add_gtest)

# helper function to register check that results were generated (#580)
# this one specifically targets rostest. rostest requires different
# arguments as cmake doesn't know the name of the output file
macro(_rosbuild_check_rostest_result test_name test_pkg test_file)
  add_custom_target(${test_name}_result
                    COMMAND ${rostest_path}/bin/rostest-check-results --rostest ${test_pkg} ${test_file}
                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
		    VERBATIM)

  add_dependencies(test-results-run ${test_name}_result)	 
endmacro(_rosbuild_check_rostest_result test_name)

macro(_rosbuild_add_rostest file)

  # Check that the file exists, #1621
  set(_file_name _file_name-NOTFOUND)
  find_file(_file_name ${file} ${PROJECT_SOURCE_DIR} /)
  if(NOT _file_name)
    message(FATAL_ERROR "Can't find rostest file \"${file}\"")
  endif(NOT _file_name)

  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname ${file})

  # Create target for this test
  add_custom_target(rostest_${_testname}
                    COMMAND ${ARGN} rostest ${file}
                    DEPENDS ${file}
                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                    VERBATIM)

  # Make sure all test programs are built before running this test
  # but not if rosbuild_test_nobuild is set, #3008
  if(NOT rosbuild_test_nobuild)
    add_dependencies(rostest_${_testname} tests)
  endif(NOT rosbuild_test_nobuild)

  # rostest-check-results will do the magic of fixing an incorrect file extension
  # Don't register to check rostest output here, because we may have gotten
  # here through registration of a future test.  Eventually, we should pass
  # in the overriding target (e.g., test-results vs. test-future-results).
  # For now, we call _rosbuild_check_rostest_xml_result() in
  # rosbuild_add_rostest() 
  # and rosbuild_add_rostest_future() instead.
  #_rosbuild_check_rostest_result(rostest_${_testname} ${PROJECT_NAME} ${file})
endmacro(_rosbuild_add_rostest)

macro(_rosbuild_add_pyunit file)
  # Look for optional TIMEOUT argument, #2645
  parse_arguments(_pyunit "TIMEOUT" "" ${ARGN})
  if(NOT _pyunit_TIMEOUT)
    set(_pyunit_TIMEOUT 60.0)
  endif(NOT _pyunit_TIMEOUT)

  # Check that the file exists, #1621
  set(_file_name _file_name-NOTFOUND)
  find_file(_file_name ${file} ${PROJECT_SOURCE_DIR} /)
  if(NOT _file_name)
    message(FATAL_ERROR "Can't find pyunit file \"${file}\"")
  endif(NOT _file_name)

  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname ${file})

  # We look for ROS_TEST_COVERAGE=1
  # to indicate that coverage reports are being requested.
  if("$ENV{ROS_TEST_COVERAGE}" STREQUAL "1")
    set(_covarg "--cov")
  else("$ENV{ROS_TEST_COVERAGE}" STREQUAL "1")
    set(_covarg)
  endif("$ENV{ROS_TEST_COVERAGE}" STREQUAL "1")

  # Create target for this test
  # We use rostest to call the executable to get process control, #1629
  add_custom_target(pyunit_${_testname}
                    COMMAND rostest --bare --bare-name=${_testname} --bare-limit=${_pyunit_TIMEOUT} -- python ${file} ${_covarg}
                    DEPENDS ${file}
                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                    VERBATIM)

  # Make sure all test programs are built before running this test
  # but not if rosbuild_test_nobuild is set, #3008
  if(NOT rosbuild_test_nobuild)
    add_dependencies(pyunit_${_testname} tests)
  endif(NOT rosbuild_test_nobuild)

endmacro(_rosbuild_add_pyunit)

# Actual signature:
#  _rosbuild_add_roslaunch_check file var=val var=val...
macro(_rosbuild_add_roslaunch_check file)
  # Check that the file exists, #1621
  set(_file_name _file_name-NOTFOUND)
  find_file(_file_name ${file} ${CMAKE_CURRENT_SOURCE_DIR} /)
  if(NOT _file_name)
    message(FATAL_ERROR "Can't find roslaunch file or directory \"${file}\"")
  endif(NOT _file_name)

  # Find rostest
  rosbuild_invoke_rospack("" rostest path find rostest)
  # Create a legal target name, in case the target name has slashes it
  string(REPLACE "/" "_" _testname ${file})
  
  # Create target for this test
  add_custom_target(roslaunch_check_${_testname}
                    COMMAND ${rostest_path}/bin/roslaunch-check.py ${file} ${ARGN}
                    DEPENDS ${file}
                    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                    VERBATIM)
  
  # Make sure all test programs are built before running this test
  # but not if rosbuild_test_nobuild is set, #3008
  if(NOT rosbuild_test_nobuild)
    add_dependencies(roslaunch_check_${_testname} tests)
  endif(NOT rosbuild_test_nobuild)
  
endmacro(_rosbuild_add_roslaunch_check)

macro(_rosbuild_wget_and_build tarball tarball_url tarball_dir unpack_cmd configure_cm make_cmd install_cmd)
  find_package(Wget REQUIRED)

  _rosbuild_dequote_string(_unpack_cmd ${unpack_cmd})
  _rosbuild_dequote_string(_configure_cmd ${configure_cmd})
  _rosbuild_dequote_string(_make_cmd ${make_cmd})
  _rosbuild_dequote_string(_install_cmd ${install_cmd})

  add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/${tarball}
                     COMMAND ${WGET_EXECUTABLE} ${tarball_url} -O ${tarball}
		     VERBATIM)
  
  add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/${tarball_dir}
                     COMMAND ${_unpack_cmd} ${tarball}
                     COMMAND touch ${tarball_dir}
		     DEPENDS ${PROJECT_BINARY_DIR}/${tarball}
		     VERBATIM)
  
  add_custom_command(OUTPUT ${PROJECT_BINARY_DIR}/installed
                     COMMAND cmake -E chdir ${PROJECT_BINARY_DIR}/${tarball_dir} ${_configure_cmd}
                     COMMAND cmake -E chdir ${PROJECT_BINARY_DIR}/${tarball_dir} ${_make_cmd}
                     COMMAND cmake -E chdir ${PROJECT_BINARY_DIR}/${tarball_dir} ${_install_cmd}
                     COMMAND touch ${PROJECT_BINARY_DIR}/installed
		     DEPENDS ${PROJECT_BINARY_DIR}/${tarball_dir}
                     VERBATIM)
  
  add_custom_target(fetch_and_build ALL
                    DEPENDS ${PROJECT_BINARY_DIR}/installed)
endmacro(_rosbuild_wget_and_build)

macro(_rosbuild_add_library lib libname type)

  add_library(${lib} ${type} ${ARGN})

  if(${type} STREQUAL STATIC)
    # Set output name to be the same as shared lib (may not work on Windows)
    set_target_properties(${lib} PROPERTIES OUTPUT_NAME ${libname})
    # Also add -fPIC, because CMake leaves it out when building static
    # libs, even though it's necessary on 64-bit machines for linking this
    # lib against shared libs downstream.
    rosbuild_add_compile_flags(${lib} -fPIC)
  endif(${type} STREQUAL STATIC)
  
  # Add explicit dependency of each file on our manifest.xml and those of
  # our dependencies
  # The SOURCES property seems to be available only since 2.6.  Yar.
  #get_target_property(_srclist ${lib} SOURCES)
  set(_srclist ${ARGN})
  foreach(_src ${_srclist})
    set(_file_name _file_name-NOTFOUND)
    find_file(_file_name ${_src} ${CMAKE_CURRENT_SOURCE_DIR} /)
    if(NOT _file_name)
      message("[rosbuild] Couldn't find source file ${_src}; assuming that it is in ${CMAKE_CURRENT_SOURCE_DIR} and will be generated later")
      set(_file_name ${CMAKE_CURRENT_SOURCE_DIR}/${_src})
    endif(NOT _file_name)
    add_file_dependencies(${_file_name} ${ROS_MANIFEST_LIST}) 
  endforeach(_src)

  # Prevent deletion of existing lib of same name
  set_target_properties(${lib} PROPERTIES CLEAN_DIRECT_OUTPUT 1)
  # Attach compile and link flags
  rosbuild_add_compile_flags(${lib} ${${PROJECT_NAME}_CFLAGS_OTHER})
  rosbuild_add_link_flags(${lib} ${${PROJECT_NAME}_LDFLAGS_OTHER})
  # Link lib against dependent libs
  target_link_libraries(${lib} ${${PROJECT_NAME}_LIBRARIES})

  # Add ROS-wide compile and link flags (usually things like -Wall).  These
  # are set in rosconfig.cmake.
  rosbuild_add_compile_flags(${lib} ${ROS_COMPILE_FLAGS})
  rosbuild_add_link_flags(${lib} ${ROS_LINK_FLAGS})

  # Make sure to do any prebuild work (e.g., msg/srv generation) before
  # building this target.
  add_dependencies(${lib} ${PROJECT_NAME}_codegen)
  # message("${lib} <<== ${ROSBUILD_GEN_TARGETS}")
endmacro(_rosbuild_add_library)

macro(_rosbuild_get_clock var)
  execute_process(
    COMMAND ${ROSBUILD_SUBSHELL}
    python -c "import time; print time.time()"
    OUTPUT_VARIABLE ${var}
    ERROR_VARIABLE _time_error
    RESULT_VARIABLE _time_failed
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(_time_failed)
    message("[rosbuild] Error from calling to Python to get system time:")
    message("${_time_error}")
    message(FATAL_ERROR "[rosbuild] Failed to get system time; aborting")
  endif(_time_failed)
endmacro(_rosbuild_get_clock var)

macro(_rosbuild_cmakelist_to_pylist _cmakelist _pylist)
    # Convert a CMake list into a Python list
    set(_pyl "[")
    foreach(_f ${_cmakelist})
      set(_pyl "${_pyl} '${_f}',")
    endforeach(_f)
    set(_pyl "${_pyl}]")
    set(${_pylist} "${_pyl}")
endmacro(_rosbuild_cmakelist_to_pylist _cmakelist _pylist)

macro(_rosbuild_compare_manifests var _t _c _m)
  if("${_t}" STREQUAL "")
    # No time was given, so it's too old
    set(${var} 1)
  else("${_t}" STREQUAL "")
    _rosbuild_cmakelist_to_pylist("${_m}" _pylist)
    _rosbuild_cmakelist_to_pylist("${_c}" _cached_pylist)

    # Call Python to compare the provided time to the latest mtime on all
    # the files
    execute_process(
      COMMAND ${ROSBUILD_SUBSHELL}
      python -c "import os; print 1 if set(${_pylist}) != set(${_cached_pylist}) or ${_t} < max(os.stat(f).st_mtime for f in ${_pylist}) else 0;"
      OUTPUT_VARIABLE ${var}
      ERROR_VARIABLE _mtime_error
      RESULT_VARIABLE _mtime_failed
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(_mtime_failed)
      message("[rosbuild] Error from calling to Python to get latest mtime:")
      message("${_mtime_error}")
      message(FATAL_ERROR "[rosbuild] Failed to get latest mtime; aborting")
    endif(_mtime_failed)
  endif("${_t}" STREQUAL "")
endmacro(_rosbuild_compare_manifests var _t)

#
# parse_arguments() taken from
# http://www.itk.org/Wiki/CMakeMacroParseArguments
# 
# 
#
macro(parse_arguments prefix arg_names option_names)
  set(DEFAULT_ARGS)
  foreach(arg_name ${arg_names})    
    set(${prefix}_${arg_name})
  endforeach()
  foreach(option ${option_names})
    set(${prefix}_${option} FALSE)
  endforeach()

  set(current_arg_name DEFAULT_ARGS)
  set(current_arg_list)
  foreach(arg ${ARGN})            
    set(larg_names ${arg_names})    
    list(FIND larg_names "${arg}" is_arg_name)                   
    if (is_arg_name GREATER -1)
      set(${prefix}_${current_arg_name} ${current_arg_list})
      set(current_arg_name ${arg})
      set(current_arg_list)
    else()
      set(loption_names ${option_names})    
      list(FIND loption_names "${arg}" is_option)            
      if(is_option GREATER -1)
        set(${prefix}_${arg} TRUE)
      else()
        set(current_arg_list ${current_arg_list} ${arg})
      endif()
    endif()
  endforeach()
  set(${prefix}_${current_arg_name} ${current_arg_list})
endmacro()

# Internal macros above
###############################################################################



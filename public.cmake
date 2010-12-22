# Set a flag to indicate that rosbuild_init() has not been called, so that
# we can later catch out-of-order calls to macros that must be called prior
# to rosbuild_init(), related to #1487.
set(ROSBUILD_init_called 0)

find_library(GTEST_LIBRARIES gtest)
set(GTEST_INCLUDE_DIR /usr/include)

# Use this package to get add_file_dependencies()
include(AddFileDependencies)
# Used to check if a function exists
include(CheckFunctionExists)

macro(rosbuild_find_ros_package)
endmacro()

macro(rosbuild_assert_file_exists FNAME)
  if(NOT EXISTS ${FNAME})
    message(FATAL_ERROR "File ${FNAME} doesn't exist")
  endif()
endmacro()

# Retrieve the current COMPILE_FLAGS for the given target, append the new
# ones, and set the result.
macro(rosbuild_add_compile_flags target)
  set(args ${ARGN})
  separate_arguments(args)
  get_target_property(_flags ${target} COMPILE_FLAGS)
  if(NOT _flags)
    set(_flags ${ARGN})
  else()
    separate_arguments(_flags)
    list(APPEND _flags "${args}")
  endif()

  _rosbuild_list_to_string(_flags_str "${_flags}")
  set_target_properties(${target} PROPERTIES
                        COMPILE_FLAGS "${_flags_str}")
endmacro(rosbuild_add_compile_flags)

# Retrieve the current COMPILE_FLAGS for the given target, remove the given
# ones, and set the result.
macro(rosbuild_remove_compile_flags target)
  set(args ${ARGN})
  separate_arguments(args)
  get_target_property(_flags ${target} COMPILE_FLAGS)
  separate_arguments(_flags)
  list(REMOVE_ITEM _flags ${args})

  _rosbuild_list_to_string(_flags_str "${_flags}")
  set_target_properties(${target} PROPERTIES
                        COMPILE_FLAGS "${_flags_str}")
endmacro(rosbuild_remove_compile_flags)

# Retrieve the current LINK_FLAGS for the given target, append the new
# ones, and set the result.
macro(rosbuild_add_link_flags target)
  set(args ${ARGN})
  separate_arguments(args)
  get_target_property(_flags ${target} LINK_FLAGS)
  if(NOT _flags)
    set(_flags ${ARGN})
  else()
    separate_arguments(_flags)
    list(APPEND _flags "${args}")
  endif()

  _rosbuild_list_to_string(_flags_str "${_flags}")
  set_target_properties(${target} PROPERTIES
                        LINK_FLAGS "${_flags_str}")
endmacro(rosbuild_add_link_flags)

# Retrieve the current LINK_FLAGS for the given target, remove the given
# ones, and set the result.
macro(rosbuild_remove_link_flags target)
  set(args ${ARGN})
  separate_arguments(args)
  get_target_property(_flags ${target} LINK_FLAGS)
  separate_arguments(_flags)
  list(REMOVE_ITEM _flags ${args})

  _rosbuild_list_to_string(_flags_str "${_flags}")
  set_target_properties(${target} PROPERTIES
                        LINK_FLAGS "${_flags_str}")
endmacro(rosbuild_remove_link_flags)

macro(rosbuild_invoke_rospack pkgname _prefix _varname)
  message(FATAL_ERROR "Don't invoke rospack.")
endmacro()

###############################################################################
# This is the user's main entry point.  A *lot* of work gets done here.  It
# should probably be split up into multiple macros.
macro(rosbuild_init)
  # Record that we've been called
  set(ROSBUILD_init_called 1)

  include(${CMAKE_CURRENT_BINARY_DIR}/project.cmake OPTIONAL)

  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/rostest.list 
    "#\n# automatically generated test file for project ${PROJECT_NAME}\n#\n")

  # Infer package name from directory name.
  # get_filename_component(_project ${CMAKE_CURRENT_SOURCE_DIR} NAME)
  # message("-- + ${_project}")

  # project(${_project})

  set(PROJECT_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/bin)
  # Must call include(rosconfig) after project, because rosconfig uses
  # PROJECT_SOURCE_DIR
  include($ENV{ROS_ROOT}/core/rosbuild/rosconfig.cmake)

  # Check that PYTHONPATH includes roslib
  # _rosbuild_check_pythonpath()

  # Check that manifest.xml is valid
  _rosbuild_check_manifest()

  # Check that the package directory is correct
  # _rosbuild_check_package_location()

  # Add ROS_PACKAGE_NAME define
  add_definitions(-DROS_PACKAGE_NAME='\"${PROJECT_NAME}\"')

  # ROS_BUILD_TYPE is set by rosconfig
  # RelWithAsserts is our own type, not supported by CMake
  if("${ROS_BUILD_TYPE}" STREQUAL "RelWithAsserts")
    set(CMAKE_BUILD_TYPE "")
    set(ROS_COMPILE_FLAGS "-O3 ${ROS_COMPILE_FLAGS}")
  else()
    set(CMAKE_BUILD_TYPE ${ROS_BUILD_TYPE})
  endif()

  # Set default output directories
  set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR}/bin)
  set(LIBRARY_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR}/lib)

  # By default, look in the local include dir
  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

  set(_prefix ${PROJECT_NAME})
  set(${_prefix}_INCLUDEDIR "" CACHE INTERNAL "")

  # Get the full paths to the manifests for all packages on which 
  # we depend
  # rosbuild_invoke_rospack(${PROJECT_NAME} _rospack deps_manifests_invoke_result deps-manifests)
  # rosbuild_invoke_rospack(${PROJECT_NAME} _rospack msgsrv_gen_invoke_result deps-msgsrv)
  set(ROS_MANIFEST_LIST "${PROJECT_SOURCE_DIR}/manifest.xml ${_rospack_deps_manifests_invoke_result} ${_rospack_msgsrv_gen_invoke_result}")
  # convert whitespace-separated string to ;-separated list
  separate_arguments(ROS_MANIFEST_LIST)

  # Check the time at which we last cached flags against the latest
  # modification time for all manifests that we depend on.  If our cache
  # time is smaller, then we need to rebuild our cached values by calling
  # out to rospack to get flags.  This is an optimization in the service of
  # speeding up the build, #2109.
  # _rosbuild_compare_manifests(_rebuild_cache "${_rosbuild_cached_flag_time}" "${${_prefix}_cached_manifest_list}" "${ROS_MANIFEST_LIST}")
  if(FALSE)#_rebuild_cache)
    # Explicitly unset all cached variables, to avoid possible accumulation
    # across builds, #2389.
    set(${_prefix}_INCLUDE_DIRS "" CACHE INTERNAL "")
    set(${_prefix}_CFLAGS_OTHER "" CACHE INTERNAL "")
    set(${_prefix}_LIBRARY_DIRS "" CACHE INTERNAL "")
    set(${_prefix}_LIBRARIES "" CACHE INTERNAL "")
    set(${_prefix}_LDFLAGS_OTHER "" CACHE INTERNAL "")
    set(${_prefix}_cached_manifest_list "" CACHE INTERNAL "")

    message("[rosbuild] Cached build flags older than manifests; calling rospack to get flags")
    # Get the include dirs
    rosbuild_invoke_rospack(${PROJECT_NAME} ${_prefix} INCLUDE_DIRS cflags-only-I --deps-only)
    #message("${pkgname} include dirs: ${${_prefix}_INCLUDE_DIRS}")
    set(${_prefix}_INCLUDE_DIRS ${${_prefix}_INCLUDE_DIRS} CACHE INTERNAL "")
  
    # Get the other cflags
    rosbuild_invoke_rospack(${PROJECT_NAME} ${_prefix} temp cflags-only-other --deps-only)
    _rosbuild_list_to_string(${_prefix}_CFLAGS_OTHER "${${_prefix}_temp}")
    #message("${pkgname} other cflags: ${${_prefix}_CFLAGS_OTHER}")
    set(${_prefix}_CFLAGS_OTHER ${${_prefix}_CFLAGS_OTHER} CACHE INTERNAL "")
  
    # Get the lib dirs
    rosbuild_invoke_rospack(${PROJECT_NAME} ${_prefix} LIBRARY_DIRS libs-only-L --deps-only)
    #message("${pkgname} library dirs: ${${_prefix}_LIBRARY_DIRS}")
    set(${_prefix}_LIBRARY_DIRS ${${_prefix}_LIBRARY_DIRS} CACHE INTERNAL "")
  
    # Get the libs
    rosbuild_invoke_rospack(${PROJECT_NAME} ${_prefix} LIBRARIES libs-only-l --deps-only)
    #
    # The following code removes duplicate libraries from the link line,
    # saving only the last one.
    #
    list(REVERSE ${_prefix}_LIBRARIES)
    #list(REMOVE_DUPLICATES ${_prefix}_LIBRARIES)
    _rosbuild_list_remove_duplicates("${${_prefix}_LIBRARIES}" _tmplist)
    set(${_prefix}_LIBRARIES ${_tmplist})
    list(REVERSE ${_prefix}_LIBRARIES)
  
    # Also throw in the libs that we want to link everything against (only
    # use case for this so far is -lgcov when building with code coverage
    # support).
    list(APPEND ${_prefix}_LIBRARIES "${ROS_LINK_LIBS}")
    set(${_prefix}_LIBRARIES ${${_prefix}_LIBRARIES} CACHE INTERNAL "")
  
    # Get the other lflags
    rosbuild_invoke_rospack(${PROJECT_NAME} ${_prefix} temp libs-only-other --deps-only)
    _rosbuild_list_to_string(${_prefix}_LDFLAGS_OTHER "${${_prefix}_temp}")
    #message("${pkgname} other ldflags: ${${_prefix}_LDFLAGS_OTHER}")
    set(${_prefix}_LDFLAGS_OTHER ${${_prefix}_LDFLAGS_OTHER} CACHE INTERNAL "")

    # Record the time at which we cached those values
    _rosbuild_get_clock(_time)
    set(_rosbuild_cached_flag_time ${_time} CACHE INTERNAL "")
    set(${_prefix}_cached_manifest_list ${ROS_MANIFEST_LIST} CACHE INTERNAL "")
  endif()#_rebuild_cache)

  # Use the (possibly cached) values returned by rospack.
  include_directories(${${_prefix}_INCLUDE_DIRS})
  link_directories(${${_prefix}_LIBRARY_DIRS})

  #
  # Catch absolute pathnames to archive libraries and bracket them with
  # linker args necessary to force extraction of the entire archive.
  #
  # The OS X linker doesn't accept the -whole-archive and -no-whole-archive
  # arguments.
  #
  if(NOT APPLE)
    foreach(_lib ${${_prefix}_LIBRARIES})
      if(_lib MATCHES "/[^ ]*\\.a")
        set(_bracket_str "-Wl,-whole-archive ${_lib} -Wl,-no-whole-archive")
        list(APPEND ${_prefix}_LDFLAGS_OTHER "${_bracket_str}")
      endif()
    endforeach(_lib)
  endif()

  # Set up the test targets.  Subsequent calls to rosbuild_add_gtest and
  # friends add targets and dependencies from these targets.
  #
  set(rostest_path ${ROS_ROOT}/test/rostest)
  
  # Record where we're going to put test results (#2003)
  execute_process(COMMAND ${ROSBUILD_SUBSHELL} ${rostest_path}/bin/test-results-dir
                  OUTPUT_VARIABLE rosbuild_test_results_dir
                  RESULT_VARIABLE _test_results_dir_failed
                  ERROR_VARIABLE _test_results_dir_err
                  OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(_test_results_dir_failed)
    message(FATAL_ERROR "Failed to invoke rostest/bin/test-results-dir: ${_test_results_dir_err}")
  endif()

  # The 'tests' target builds the test program
  add_custom_target(tests)
  # The 'test' target runs all but the future tests
  add_custom_target(test)
  # We need to build tests before running them.  Addition of this
  # dependency also ensures that old test results get cleaned prior to a
  # new test run.
  # but not if rosbuild_test_nobuild is set, #3008
  if(NOT rosbuild_test_nobuild)
    add_dependencies(test tests)
  endif()
  
  # Clean out previous test results before running tests.  Use bash
  # conditional to ignore failures (most often happens when a stale NFS
  # handle lingers in the test results directory), because CMake doesn't
  # seem to be able to do it.
  add_custom_target(clean-test-results
                    if ! rm -rf ${rosbuild_test_results_dir}/${PROJECT_NAME}\; then echo "WARNING: failed to remove test-results directory"\; fi)
  # Make the tests target depend on clean-test-results, which will ensure
  # that test results are deleted before we try to build tests, and thus
  # before we try to run tests.
  add_dependencies(tests clean-test-results)
  # The 'test-future' target runs the future tests
  add_custom_target(test-future)


  add_custom_target(test-results-run)
  add_custom_target(test-results
                    COMMAND ${rostest_path}/bin/rostest-results --nodeps ${PROJECT_NAME})
  add_dependencies(test-results test-results-run)
  # Do we want coverage reporting (only matters for Python, because
  # Bullseye already collects everything into a single file).
  if("$ENV{ROS_TEST_COVERAGE}" STREQUAL "1")
    add_custom_target(test-results-coverage
                      COMMAND ${rostest_path}/bin/coverage-html
                      WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
    # Make tests run before collecting coverage results
    add_dependencies(test-results-coverage test-results-run)
    # Make coverage collection happen
    add_dependencies(test-results test-results-coverage)
  endif()

  # Figure out which languages we're building for.  "rospack langs" will
  # return a list of packages that:
  #   - depend directly on roslang
  #   - are not in the env var ROS_LANG_DISABLE
  # rosbuild_invoke_rospack("" _roslang LANGS langs)
  # separate_arguments(_roslang_LANGS)
  # message("roslang_LANGS=${_roslang_LANGS}")

  # Create targets for client libs attach their message-generation output to
  #add_custom_target(rospack_genmsg)
  #add_custom_target(rospack_gensrv)

  # Add a target that will fire before doing message or service generation.
  # This is used by packages that do automatic generation of message and
  # service files.
  #add_custom_target(rosbuild_premsgsrvgen)

  # Add a target that will fire before compiling anything.  This is used by
  # message and service generation, as well as things outside of ros, like
  # dynamic_reconfigure.
  #add_custom_target(rosbuild_precompile)

  # The rospack_genmsg_libexe target is defined for backward compatibility,
  # and will eventually be removed.
  #add_custom_target(rospack_genmsg_libexe)
  #add_dependencies(rosbuild_precompile rospack_genmsg_libexe)
  
  # Also collect cmake fragments exported by packages that depend on
  # rosbuild.  This behavior is deprecated, in favor of using
  # rosbuild_include() to explicitly include cmake code from other packages.
  rosbuild_invoke_rospack(
    rosbuild _rosbuild EXPORTS plugins --attrib=cmake --top=${PROJECT_NAME})
  list(LENGTH _rosbuild_EXPORTS _rosbuild_EXPORTS_length)

  # rospack plugins outputs the list as:
  # <package name> <attribute value>
  # Here we remove <package name> in all cases by:
  # 1) Remove the first element of the returned list
  # 2) Search for all instances of <newline><string><semicolon>, replacing them with just a semicolon

  # 1) Remove the first package name if the list has at least one element
  if (${_rosbuild_EXPORTS_length} GREATER 0)
    list(REMOVE_AT _rosbuild_EXPORTS 0)
  endif()

  # 2) Remove the rest of the package names
  string(REGEX REPLACE "\n[^;]*;" ";" _rosbuild_EXPORTS_stripped "${_rosbuild_EXPORTS}")

  set(_rosbuild_EXPORTS "" CACHE INTERNAL "")

  foreach(_f ${_rosbuild_EXPORTS_stripped})
    list(APPEND _cmake_fragments ${_f})
    message("\n[rosbuild] WARNING: the file ${_f} is being included automatically.  This behavior is deprecated.  The package containing that file should instead export the directory containing the file, and you should use rosbuild_include() to include the file explicitly.\n")
  endforeach(_f)

  # Now include them all
  foreach(_f ${_cmake_fragments})
    if(NOT EXISTS ${_f})
      message(FATAL_ERROR "Cannot include non-existent exported cmake file ${_f}")
    endif()
    # Include this cmake fragment; presumably it will do /
    # provide something useful.  Only include each file once (a file
    # might be multiply referenced because of package dependencies
    # dependencies).
    if(NOT ${_f}_INCLUDED)
      message("[rosbuild] Including ${_f}")
      include(${_f})
      set(${_f}_INCLUDED Y)
    endif()
  endforeach(_f)


  #
  # Gather the gtest build flags, for use when building unit tests.  We
  # don't require the user to declare a dependency on gtest.
  #
  #rosbuild_invoke_rospack(gtest _gtest PACKAGE_PATH find)
  #include_directories(${_gtest_PACKAGE_PATH}/gtest/include)
  #link_directories(${_gtest_PACKAGE_PATH}/gtest/lib)
  #set(_gtest_LIBRARIES -lgtest)
  #set(_gtest_CFLAGS_OTHER "")
  #set(_gtest_LDFLAGS_OTHER "-Wl,-rpath,${_gtest_PACKAGE_PATH}/gtest/lib")
  
  #
  # The following code removes duplicate libraries from the link line,
  # saving only the last one.
  #
  #list(REVERSE _gtest_LIBRARIES)
  #list(REMOVE_DUPLICATES _gtest_LIBRARIES)
  #_rosbuild_list_remove_duplicates(${_gtest_LIBRARIES} _tmplist)
  #set(_gtest_LIBRARIES ${_tmplist})
  #list(REVERSE _gtest_LIBRARIES)

  # This will set STACK_NAME
  set(ROS_PACKAGE_INSTALL_PREFIX ${ROS_INSTALL_PREFIX}/lib/ros/${STACK_NAME}/${PROJECT_NAME})

  install(FILES manifest.xml DESTINATION ${ROS_PACKAGE_INSTALL_PREFIX})

endmacro(rosbuild_init)
###############################################################################

# A wrapper around add_executable(), using info from the rospack
# invocation to set up compiling and linking.
macro(rosbuild_add_executable exe)

  parse_arguments(_var "" "EXCLUDE_FROM_ALL;PACKAGE_INSTALL;ROOT_INSTALL" ${ARGN})

  if (_var_EXCLUDE_FROM_ALL)
    add_executable(${exe} EXCLUDE_FROM_ALL ${_var_DEFAULT_ARGS})
  else()
    add_executable(${exe} ${_var_DEFAULT_ARGS})
    install(TARGETS ${exe}
      RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin/${PROJECT_NAME})
  endif()

  get_filename_component(thisexe_path ${exe} PATH)
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin/${thisexe_path})
  rosbuild_add_compile_flags(${exe} ${${PROJECT_NAME}_CFLAGS_OTHER})
  rosbuild_add_link_flags(${exe} ${${PROJECT_NAME}_LDFLAGS_OTHER})

  if(ROS_BUILD_STATIC_EXES AND ${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
    # This will probably only work on Linux.  The LINK_SEARCH_END_STATIC
    # property should be sufficient, but it doesn't appear to work
    # properly.
    rosbuild_add_link_flags(${exe} -static-libgcc -Wl,-Bstatic)
  endif()

  target_link_libraries(${exe} ${${PROJECT_NAME}_LIBRARIES} ${EXPORTED_TO_ME_LIBRARIES})

  # Add ROS-wide compile and link flags (usually things like -Wall).  These
  # are set in rosconfig.cmake.
  rosbuild_add_compile_flags(${exe} ${ROS_COMPILE_FLAGS})
  rosbuild_add_link_flags(${exe} ${ROS_LINK_FLAGS})

  add_dependencies(${exe} ${PROJECT_NAME}_gen_cpp)
  # If we're linking boost statically, we have to force allow multiple definitions because
  # rospack does not remove duplicates
  if ("$ENV{ROS_BOOST_LINK}" STREQUAL "static")
    rosbuild_add_link_flags(${exe} "-Wl,--allow-multiple-definition")
  endif()

  
endmacro(rosbuild_add_executable)

#
# Wrapper around add_library.  We can build shared static and shared libs, and
# set up compile and link flags for both.
#
macro(rosbuild_add_library lib)

  parse_arguments(_var "" "PACKAGE_INSTALL;ROOT_INSTALL" ${ARGN})

  # Sanity check; must build at least one kind of library.
  if(NOT ROS_BUILD_STATIC_LIBS AND NOT ROS_BUILD_SHARED_LIBS)
    message(FATAL_ERROR "Neither shared nor static libraries are enabled.  Please set either ROS_BUILD_STATIC_LIBS or ROS_BUILD_SHARED_LIBS to true in your $ROS_ROOT/rosconfig.cmake")
  endif()

  # Sanity check; it's too hard to support building shared libs and static
  # executables.
  if(ROS_BUILD_STATIC_EXES AND ROS_BUILD_SHARED_LIBS)
    message(FATAL_ERROR "Static executables are requested, but so are shared libs. This configuration is unsupported.  Please either set ROS_BUILD_SHARED_LIBS to false or set ROS_BUILD_STATIC_EXES to false.")
  endif()

  # What are we building?
  if(ROS_BUILD_SHARED_LIBS)
    # If shared libs are being built, they get the default CMake target name
    # No matter what, the libraries get the same name in the end.
    _rosbuild_add_library(${lib} ${lib} SHARED ${_var_DEFAULT_ARGS})
  endif()

  if(ROS_BUILD_STATIC_LIBS)
    # If we're only building static libs, then they get the default CMake
    # target name.
    if(NOT ROS_BUILD_SHARED_LIBS)
      set(static_lib_name "${lib}")
    else()
      set(static_lib_name "${lib}-static")
    endif()

    _rosbuild_add_library(${static_lib_name} ${lib} STATIC ${_var_DEFAULT_ARGS})
  endif()

  target_link_libraries(${lib} ${EXPORTED_TO_ME_LIBRARIES})

  install(TARGETS ${lib}
    LIBRARY DESTINATION ${CMAKE_INSTALL_PREFIX}/lib  # shared objects
    ARCHIVE DESTINATION ${CMAKE_INSTALL_PREFIX}/lib  # statics
    )
endmacro(rosbuild_add_library)

macro(rosbuild_install)
#  separate_arguments(ARGN)
  install(${ARGN})
endmacro()


macro(rosbuild_install_directories)
  parse_arguments(_var "" "INSTALL_TO_ROOT" ${ARGN})
  if (_var_INSTALL_TO_ROOT)
    install(DIRECTORY ${_var_DEFAULT_ARGS}
      DESTINATION ${ROS_INSTALL_PREFIX})
  else()
    install(DIRECTORY ${_var_DEFAULT_ARGS}
      DESTINATION ${ROS_PACKAGE_INSTALL_PREFIX})
  endif()
endmacro()

macro(rosbuild_install_programs)
  parse_arguments(_var "" "INSTALL_TO_ROOT" ${ARGN})
  if (_var_INSTALL_TO_ROOT)
    install(PROGRAMS ${_var_DEFAULT_ARGS}
      DESTINATION ${ROS_INSTALL_PREFIX}/bin)
  else()
    install(PROGRAMS ${_var_DEFAULT_ARGS}
      DESTINATION ${ROS_PACKAGE_INSTALL_PREFIX}/bin)
  endif()
endmacro()

# Wrapper around add_library for the specific case of building a MODULE,
# which works a little differently on dyld systems (e.g., OS X)
macro(rosbuild_add_library_module lib)
  _rosbuild_add_library(${lib} ${lib} MODULE ${ARGN})
endmacro(rosbuild_add_library_module)

# Explicitly add flags for gtest.  We do this here, instead of using
# manifest dependencies, because there are situations in which it is
# undesirable to link in gtest where's it's not being used.  gtest is
# part of the "core" build that happens during a 'make' in ros, so we can
# assume that's already built.
macro(rosbuild_add_gtest_build_flags exe)
  rosbuild_add_compile_flags(${exe} ${GTEST_CFLAGS_OTHER})
  target_link_libraries(${exe} ${GTEST_LIBRARIES})
  rosbuild_add_link_flags(${exe} ${GTEST_LDFLAGS_OTHER})
  rosbuild_declare_test(${exe})
endmacro(rosbuild_add_gtest_build_flags)

# Declare an executable to be a test harness, which excludes it from the
# all target, and adds a dependency to the tests target.
macro(rosbuild_declare_test exe)
  add_dependencies(tests ${exe})
endmacro(rosbuild_declare_test)

# A helper to create test programs.  It calls rosbuild_add_executable() to
# create the program, and augments a test target that was created in the
# call rospack()
macro(rosbuild_add_gtest exe)
  _rosbuild_add_gtest(${ARGV})
  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname ${exe})
  # add_dependencies(test test_${_testname})
  # Register check for test output
  _rosbuild_check_rostest_xml_result(${_testname} 
    ${rosbuild_test_results_dir}/${PROJECT_NAME}/TEST-${_testname}.xml)
endmacro(rosbuild_add_gtest)

# A version of add_gtest that checks a label against ROS_BUILD_TEST_LABEL
macro(rosbuild_add_gtest_labeled label)
  if("$ENV{ROS_BUILD_TEST_LABEL}" STREQUAL "" OR "${label}" STREQUAL "$ENV{ROS_BUILD_TEST_LABEL}")
    rosbuild_add_gtest(${ARGN})
  endif()
endmacro(rosbuild_add_gtest_labeled)

# A helper to create test programs that are expected to fail for the near
# future.  It calls rosbuild_add_executable() to
# create the program, and augments a test target that was created in the
# call rospack()
macro(rosbuild_add_gtest_future exe)
  _rosbuild_add_gtest(${ARGV})
  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname ${exe})

  add_dependencies(test-future test_${_testname})
endmacro(rosbuild_add_gtest_future)

# A helper to run rostests. It generates a command to run rostest on
# the specified file and makes this target a dependency of test. 
macro(rosbuild_add_rostest file)
  string(REPLACE "/" "_" _testname ${file})
  _rosbuild_add_rostest(${file})

  add_dependencies(test rostest_${_testname})

  _rosbuild_check_rostest_result(rostest_${_testname} ${PROJECT_NAME} ${file})
endmacro(rosbuild_add_rostest)

# A version of add_rostest that checks a label against ROS_BUILD_TEST_LABEL
macro(rosbuild_add_rostest_labeled label)
  if("$ENV{ROS_BUILD_TEST_LABEL}" STREQUAL "" OR "${label}" STREQUAL "$ENV{ROS_BUILD_TEST_LABEL}")
    rosbuild_add_rostest(${ARGN})
  endif()
endmacro(rosbuild_add_rostest_labeled)

# A helper to run rostests that are expected to fail for the near future. 
# It generates a command to run rostest on
# the specified file and makes this target a dependency of test. 
macro(rosbuild_add_rostest_future file)
  string(REPLACE "/" "_" _testname ${file})
  _rosbuild_add_rostest(${file})
  add_dependencies(test-future rostest_${_testname})
endmacro(rosbuild_add_rostest_future)

# A helper to run Python unit tests. It generates a command to run python
# the specified file 
macro(rosbuild_add_pyunit file)
  string(REPLACE "/" "_" _testname ${file})
  _rosbuild_add_pyunit(${ARGV})
  add_dependencies(test pyunit_${_testname})
  # Register check for test output
  _rosbuild_check_rostest_xml_result(${_testname} ${rosbuild_test_results_dir}/${PROJECT_NAME}/TEST-${_testname}.xml)
endmacro(rosbuild_add_pyunit)

# A version of add_pyunit that checks a label against ROS_BUILD_TEST_LABEL
macro(rosbuild_add_pyunit_labeled label)
  if("$ENV{ROS_BUILD_TEST_LABEL}" STREQUAL "" OR "${label}" STREQUAL "$ENV{ROS_BUILD_TEST_LABEL}")
    rosbuild_add_pyunit(${ARGN})
  endif()
endmacro(rosbuild_add_pyunit_labeled)

# A helper to run Python unit tests that are expected to fail for the near
# future. It generates a command to run python
# the specified file 
macro(rosbuild_add_pyunit_future file)
  string(REPLACE "/" "_" _testname ${file})
  _rosbuild_add_pyunit(${file})
  add_dependencies(test-future pyunit_${_testname})
endmacro(rosbuild_add_pyunit_future)

# Declare as a unit test a check of a roslaunch file, or a directory
# containing roslaunch files.  Following the file/directory, you can
# specify environment variables as var=val var=val ...
macro(rosbuild_add_roslaunch_check file)
  string(REPLACE "/" "_" _testname ${file})
  _rosbuild_add_roslaunch_check(${ARGV})
  add_dependencies(test roslaunch_check_${_testname})
endmacro(rosbuild_add_roslaunch_check)

set(_ROSBUILD_GENERATED_MSG_FILES "")
macro(rosbuild_add_generated_msgs)
  if(ROSBUILD_init_called)
    message(FATAL_ERROR "rosbuild_add_generated_msgs() cannot be called after rosbuild_init()")
  endif()
  list(APPEND _ROSBUILD_GENERATED_MSG_FILES ${ARGV})
endmacro(rosbuild_add_generated_msgs)

set(_ROSBUILD_GENERATED_SRV_FILES "")
macro(rosbuild_add_generated_srvs)
  if(ROSBUILD_init_called)
    message(FATAL_ERROR "rosbuild_add_generated_srvs() cannot be called after rosbuild_init()")
  endif()
  list(APPEND _ROSBUILD_GENERATED_SRV_FILES ${ARGV})
endmacro(rosbuild_add_generated_srvs)

# Compute msg/srv depenendency list, with simple caching
macro(rosbuild_gendeps _pkg _msgfile)
  # message("ROSBUILD_GENDEPS ${_pkg} ${_msgfile}")
  # Did we already compute it?
  if(NOT ${_pkg}_${_msgfile}_GENDEPS_COMPUTED)
    # Call out to the gendeps tool to get full paths to .msg files on
    # which this one depends, for proper dependency tracking
    # ${roslib_path} was determined inside rospack()
    execute_process(
      COMMAND ${ROSBUILD_SUBSHELL} ${roslib_path}/scripts/gendeps ${_input}
      OUTPUT_VARIABLE __other_msgs
      ERROR_VARIABLE __rospack_err_ignore 
      OUTPUT_STRIP_TRAILING_WHITESPACE) 
    # message("gendeps returns ${__other_msgs}")
    # For some reason, the output from gendeps has escaped spaces in it.
    # Converting to a string and then back to a list removes them.
    _rosbuild_list_to_string(${_pkg}_${_msgfile}_GENDEPS "${__other_msgs}")
    separate_arguments(${_pkg}_${_msgfile}_GENDEPS)
    set(${_pkg}_${_msgfile}_GENDEPS_COMPUTED Y)
  endif()
endmacro(rosbuild_gendeps)

# gensrv processes srv/*.srv files into language-specific source files
macro(rosbuild_gensrv)
  # Check whether there are any .srv files
  rosbuild_get_srvs(_srvlist)
  if(NOT _srvlist)
    _rosbuild_warn("rosbuild_gensrv() was called, but no .srv files were found")
  endif()
  # Create target to trigger service generation in the case where no libs
  # or executables are made.
  # add_custom_target(rospack_gensrv_all ALL)
  # add_dependencies(rospack_gensrv_all rospack_gensrv)
  # Make the precompile target, on which libraries and executables depend,
  # depend on the message generation.
  # add_dependencies(rosbuild_precompile rospack_gensrv)
  # add in the directory that will contain the auto-generated .h files
  _rosbuild_gensrv_impl()
endmacro(rosbuild_gensrv)

# genmsg processes msg/*.msg files into language-specific source files
macro(rosbuild_genmsg)
  # Check whether there are any .msg files
  rosbuild_get_msgs(_msglist)

  if(NOT _msglist)
    _rosbuild_warn("rosbuild_genmsg() was called, but no .msg files were found")
  endif()

  # Create target to trigger message generation in the case where no libs
  # or executables are made.
  #add_custom_target(rospack_genmsg_all ALL
  #  COMMENT "rospack_genmsg_all in ${ROSBUILD_PACKAGE_RELATIVE_PATH}")

  #add_dependencies(rospack_genmsg_all rospack_genmsg)
  # Make the precompile target, on which libraries and executables depend,
  # depend on the message generation.
  #add_dependencies(rosbuild_precompile rospack_genmsg)

  _rosbuild_genmsg_impl()

endmacro(rosbuild_genmsg)

macro(rosbuild_add_boost_directories)
  add_definitions(-DBOOST_CB_DISABLE_DEBUG)
  include_directories(${BOOST_INCLUDE_DIR})
endmacro(rosbuild_add_boost_directories)

macro(rosbuild_link_boost target)

  foreach(arg ${ARGN})
    string(TOUPPER ${arg} ARG)
    target_link_libraries(${target} ${Boost_${ARG}_LIBRARY})
  endforeach()

endmacro(rosbuild_link_boost)

# Macro to download data on the tests target
# The real signature is:
#macro(rosbuild_download_test_data _url _filename _md5)
macro(rosbuild_download_test_data _url _filename)
  if("${ARGN}" STREQUAL "")
    _rosbuild_warn("The 2-argument rosbuild_download_test_data(url file) is deprecated; please switch to the 3-argument form, supplying an md5sum for the file: rosbuild_download_test_data(url file md5)")
  endif()

  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname download_data_${_filename})
  add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/${_filename} 
                     COMMAND $ENV{ROS_ROOT}/core/rosbuild/bin/download_checkmd5.py ${_url} ${PROJECT_SOURCE_DIR}/${_filename} ${ARGN}
                     VERBATIM
		     COMMENT "Downloading ${_filename}")
  add_custom_target(${_testname} DEPENDS ${PROJECT_SOURCE_DIR}/${_filename})

  add_dependencies(tests ${_testname})
endmacro(rosbuild_download_test_data)

# There's an optional 3rd arg, which is a target that should be made to
# depend on the result of untarring the file (can be ALL).
macro(rosbuild_untar_file _filename _unpacked_name)
  get_filename_component(unpack_dir ${_filename} PATH)
  add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/${_unpacked_name}
                     COMMAND rm -rf ${PROJECT_SOURCE_DIR}/${_unpacked_name}
                     COMMAND tar xvCf ${unpack_dir} ${PROJECT_SOURCE_DIR}/${_filename}
                     COMMAND touch -c ${PROJECT_SOURCE_DIR}/${_unpacked_name}
                     DEPENDS ${PROJECT_SOURCE_DIR}/${_filename}
                     WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                     VERBATIM)
  string(REPLACE "/" "_" _target_name untar_file_${_filename}_${_unpacked_name})

  if("${ARGN}" STREQUAL "ALL")
    add_custom_target(${_target_name} ALL DEPENDS ${PROJECT_SOURCE_DIR}/${_unpacked_name})
  else()
    add_custom_target(${_target_name} DEPENDS ${PROJECT_SOURCE_DIR}/${_unpacked_name})
    if(NOT "${ARGN}" STREQUAL "")
      add_dependencies(${ARGN} ${_target_name})
    endif()
  endif()
endmacro(rosbuild_untar_file)

# Macro to download data on the all target
# The real signature is:
#macro(rosbuild_download_data _url _filename _md5)
macro(rosbuild_download_data _url _filename)
  if("${ARGN}" STREQUAL "")
    _rosbuild_warn("The 2-argument rosbuild_download_data(url file) is deprecated; please switch to the 3-argument form, supplying an md5sum for the file: rosbuild_download_data(url file md5)")
  endif()
  # Create a legal target name, in case the target name has slashes in it
  string(REPLACE "/" "_" _testname download_data_${_filename})
  add_custom_command(OUTPUT ${PROJECT_SOURCE_DIR}/${_filename}
    COMMAND $ENV{ROS_ROOT}/core/rosbuild/bin/download_checkmd5.py ${_url} 
    ${PROJECT_SOURCE_DIR}/${_filename} ${ARGN} VERBATIM)
  add_custom_target(${_testname} ALL DEPENDS ${PROJECT_SOURCE_DIR}/${_filename})
endmacro(rosbuild_download_data)

macro(rosbuild_add_openmp_flags target)
  # Bullseye's wrappers appear to choke on OpenMP pragmas.  So if
  # ROS_TEST_COVERAGE is set (which indicates that we're doing a coverage
  # build with Bullseye), we make this macro a no-op.
  if("$ENV{ROS_TEST_COVERAGE}" STREQUAL "1")
    _rosbuild_warn("because ROS_TEST_COVERAGE is set, OpenMP support is disabled")
  else()
  
  # list of OpenMP flags to check
    set(_rospack_check_openmp_flags
      "-fopenmp" # gcc
      "-openmp" # icc
      "-mp" # SGI & PGI
      "-xopenmp" # Sun
      "-omp" # Tru64
      "-qsmp=omp" # AIX
      )
  
  # backup for a variable we will change
    set(_rospack_openmp_flags_backup ${CMAKE_REQUIRED_FLAGS})
  
  # mark the fact we do not yet know the flag
    set(_rospack_openmp_flag_found FALSE)
    set(_rospack_openmp_flag_value)
  
  # find an OpenMP flag that works
    foreach(_rospack_openmp_test_flag ${_rospack_check_openmp_flags})
      if(NOT _rospack_openmp_flag_found)      
        set(CMAKE_REQUIRED_FLAGS ${_rospack_openmp_test_flag})
        check_function_exists(omp_set_num_threads _rospack_openmp_function_found${_rospack_openmp_test_flag})
  	   
        if(_rospack_openmp_function_found${_rospack_openmp_test_flag})
  	set(_rospack_openmp_flag_value ${_rospack_openmp_test_flag})
  	set(_rospack_openmp_flag_found TRUE)
        endif()
      endif()
    endforeach(_rospack_openmp_test_flag ${_rospack_check_openmp_flags})
  
  # restore the CMake variable
    set(CMAKE_REQUIRED_FLAGS ${_rospack_openmp_flags_backup})
    
  # add the flags or warn
    if(_rospack_openmp_flag_found)
      rosbuild_add_compile_flags(${target} ${_rospack_openmp_flag_value})
      rosbuild_add_link_flags(${target} ${_rospack_openmp_flag_value})
    else()
      message("WARNING: OpenMP compile flag not found")
    endif()

  endif()
endmacro(rosbuild_add_openmp_flags)

macro(rosbuild_make_distribution)
  # Infer stack name from directory name.
  get_filename_component(${PROJECT_NAME} ${PROJECT_SOURCE_DIR} NAME)
  project(${PROJECT_NAME})

  # Set up for packaging
  # TODO: get version from manifest
  #set(CPACK_PACKAGE_VERSION_MAJOR "0")
  #set(CPACK_PACKAGE_VERSION_MINOR "0")
  #set(CPACK_PACKAGE_VERSION_PATCH "1")
  set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
  if("${ARGN}" STREQUAL "")
    set(CPACK_PACKAGE_VERSION "latest")
  else()
    set(CPACK_PACKAGE_VERSION "${ARGN}")
  endif()
  set(CPACK_SOURCE_PACKAGE_FILE_NAME "${PROJECT_NAME}-${CPACK_PACKAGE_VERSION}")
  set(CPACK_GENERATOR "TBZ2")
  # The CPACK_SOURCE_GENERATOR variable seems only to be obeyed in 2.6.
  # 2.4 seems to use CPACK_GENERATOR for both binary and source packages.
  set(CPACK_SOURCE_GENERATOR "TBZ2")
  # CPACK_SOURCE_IGNORE_FILES contains things we want to ignore when
  # building a source package.  We assume that the package was already
  # cleaned, so we don't need to ignore .a, .o, .so, etc.
  list(APPEND CPACK_SOURCE_IGNORE_FILES "/build/;/.svn/;.gitignore;build-failure;test-failure;rosmakeall-buildfailures-withcontext.txt;rosmakeall-profile;rosmakeall-buildfailures.txt;rosmakeall-testfailures.txt;rosmakeall-coverage.txt;/log/")
  include(CPack)
  install(FILES stack.xml DESTINATION ${ROS_INSTALL_PREFIX}/lib/ros/${PROJECT_NAME})
endmacro(rosbuild_make_distribution)

# Compute the number of hardware cores on the machine.  Intended to use for
# gating tests that have heavy processor requirements. It calls out to
# Python to do the work (UNIX only)
macro(rosbuild_count_cores num)
  execute_process(COMMAND ${ROSBUILD_SUBSHELL}
    ${ROS_ROOT}/core/rosbuild/tests/count_cores.py
    OUTPUT_VARIABLE _cores_out
    ERROR_VARIABLE _cores_error
    RESULT_VARIABLE _cores_result
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  if(_cores_result)
    message(FATAL_ERROR "Failed to run count_cores")
  endif()

  set(${num} ${_cores_out})
endmacro(rosbuild_count_cores)

# Check whether we're running as a VM Intended to use for
# gating tests that have heavy processor requirements.  It checks for
# /proc/xen
macro(rosbuild_check_for_vm var)
  set(_xen_dir _xen_dir-NOTFOUND)
  find_file(_xen_dir "xen" PATHS "/proc" NO_DEFAULT_PATH)
  if(_xen_dir)
    set(${var} 1)
  else()
    set(${var} 0)
  endif()
endmacro(rosbuild_check_for_vm var)

# Check whether there's an X display.  Intended to use in gating tests that
# require a display.
macro(rosbuild_check_for_display var)
  execute_process(COMMAND "xdpyinfo"
                  OUTPUT_VARIABLE _dummy
                  ERROR_VARIABLE _dummy
                  RESULT_VARIABLE _xdpyinfo_failed)
  if(_xdpyinfo_failed)
    set(${var} 0)
  else()
    set(${var} 1)
  endif()
endmacro(rosbuild_check_for_display)

macro(rosbuild_add_swigpy_library target lib)
  rosbuild_add_library(${target} ${ARGN})
  # swig python needs a shared library named _<modulename>.[so|dll|...]
  # this renames the output file to conform to that by prepending 
  # an underscore in place of the "lib" prefix.
  # If on Darwin, force the suffix so ".so", because the MacPorts 
  # version of Python won't find _foo.dylib for 'import _foo'
  if(APPLE)
    set_target_properties(${target}
                          PROPERTIES OUTPUT_NAME ${lib} 
                          PREFIX "_" SUFFIX ".so")
  else()
    set_target_properties(${target}
                          PROPERTIES OUTPUT_NAME ${lib} 
                          PREFIX "_")
  endif()
endmacro(rosbuild_add_swigpy_library)

macro(rosbuild_check_for_sse)
  # check for SSE extensions
  include(CheckCXXSourceRuns)
  if( CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX )
   set(SSE_FLAGS)
  
   set(CMAKE_REQUIRED_FLAGS "-msse3")
   check_cxx_source_runs("
    #include <pmmintrin.h>
  
    int main()
    {
       __m128d a, b;
       double vals[2] = {0};
       a = _mm_loadu_pd(vals);
       b = _mm_hadd_pd(a,a);
       _mm_storeu_pd(vals, b);
       return 0;
    }"
    HAS_SSE3_EXTENSIONS)
  
   set(CMAKE_REQUIRED_FLAGS "-msse2")
   check_cxx_source_runs("
    #include <emmintrin.h>
  
    int main()
    {
        __m128d a, b;
        double vals[2] = {0};
        a = _mm_loadu_pd(vals);
        b = _mm_add_pd(a,a);
        _mm_storeu_pd(vals,b);
        return 0;
     }"
     HAS_SSE2_EXTENSIONS)
  
   set(CMAKE_REQUIRED_FLAGS "-msse")
   check_cxx_source_runs("
    #include <xmmintrin.h>
    int main()
    {
        __m128 a, b;
        float vals[4] = {0};
        a = _mm_loadu_ps(vals);
        b = a;
        b = _mm_add_ps(a,b);
        _mm_storeu_ps(vals,b);
        return 0;
    }"
    HAS_SSE_EXTENSIONS)
  
   set(CMAKE_REQUIRED_FLAGS)
  
   if(HAS_SSE3_EXTENSIONS)
    set(SSE_FLAGS "-msse3 -mfpmath=sse")
    message(STATUS "[rosbuild] Found SSE3 extensions, using flags: ${SSE_FLAGS}")
   elseif(HAS_SSE2_EXTENSIONS)
    set(SSE_FLAGS "-msse2 -mfpmath=sse")
    message(STATUS "[rosbuild] Found SSE2 extensions, using flags: ${SSE_FLAGS}")
   elseif(HAS_SSE_EXTENSIONS)
    set(SSE_FLAGS "-msse -mfpmath=sse")
    message(STATUS "[rosbuild] Found SSE extensions, using flags: ${SSE_FLAGS}")
   endif()
  elseif(MSVC)
   check_cxx_source_runs("
    #include <emmintrin.h>
  
    int main()
    {
        __m128d a, b;
        double vals[2] = {0};
        a = _mm_loadu_pd(vals);
        b = _mm_add_pd(a,a);
        _mm_storeu_pd(vals,b);
        return 0;
     }"
     HAS_SSE2_EXTENSIONS)
   if( HAS_SSE2_EXTENSIONS )
    message(STATUS "[rosbuild] Found SSE2 extensions")
    set(SSE_FLAGS "/arch:SSE2 /fp:fast -D__SSE__ -D__SSE2__" )
   endif()
  endif()
endmacro(rosbuild_check_for_sse)

macro(rosbuild_include pkg module)
  # Find exported cmake directories
  rosbuild_invoke_rospack(rosbuild _rosbuild EXPORTS plugins --attrib=cmake_directory --top=${PROJECT_NAME})
  string(REGEX REPLACE "\n" ";" _rosbuild_EXPORTS_stripped "${_rosbuild_EXPORTS}")
  list(LENGTH _rosbuild_EXPORTS_stripped _rosbuild_EXPORTS_stripped_length)
  set(_idx 0)
  set(_found False)
  while(_idx LESS ${_rosbuild_EXPORTS_stripped_length} AND NOT _found)
    list(GET _rosbuild_EXPORTS_stripped ${_idx} _pkg)
    math(EXPR _idx "${_idx} + 1")
    list(GET _rosbuild_EXPORTS_stripped ${_idx} _dir)
    if("${_pkg}" STREQUAL "${pkg}")
      # message("[rosbuild] Including ${_dir}/${module}.cmake")
      include(${_dir}/${module}.cmake)
      # Poor man's break
      set(_found True)
    endif()
    math(EXPR _idx "${_idx} + 1")
  endwhile(_idx LESS ${_rosbuild_EXPORTS_stripped_length} AND NOT _found)
  if(NOT _found)
    message(FATAL_ERROR "[rosbuild] Failed to include ${module} from ${pkg}")
  endif()
endmacro(rosbuild_include)


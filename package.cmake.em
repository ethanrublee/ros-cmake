#
#   Package @PROJECT
#
#   File generated by Grob.  
#   Resistance is futile.  
#   You will be decoupled.
#
@{
def aslist(x):
    return ';'.join(x)
def asitems(x):
    return '\n  '.join(x)

}
project(@PROJECT)
add_definitions(-DROS_PACKAGE_NAME="@PROJECT")
message(STATUS " + @PROJECT")

if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/include)

  include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

  install(DIRECTORY include/
    DESTINATION include/
    COMPONENT @PROJECT
    PATTERN ".svn" EXCLUDE
    )

endif()

#
# DEPENDED_PACKAGE_PATHS = @DEPENDED_PACKAGE_PATHS
#
set(DEPENDED_PACKAGE_PATHS "@aslist(DEPENDED_PACKAGE_PATHS)")

#
# GENERATED_ACTIONS = @GENERATED_ACTIONS
#
rosbuild_actions(GENERATED_ACTIONS "@aslist(GENERATED_ACTIONS)")
rosbuild_msgs(GENERATED ${GENERATED_ACTIONS})

rosbuild_msgs(STATIC "@aslist(msgs)")
rosbuild_srvs(STATIC "@aslist(srvs)")

rosbuild_cfgs("@aslist(cfgs)")

# message("@(PROJECT)_generated: ${@(PROJECT)_generated}")

rosbuild_gentargets()

@[if len(exported_include_dirs) > 0]
#
# exported_include_dirs
#
include_directories(
  @asitems(exported_include_dirs)
  )
@[end if]

#
# These are no good, apparently
#
# @[for d in exported_include_dirs]
# install(DIRECTORY @d/ 
#   DESTINATION include/ 
#   COMPONENT @PROJECT 
#   OPTIONAL 
#   PATTERN .svn EXCLUDE
#   )
# @[end for]
#

# libs_i_need
@[if len(libs_i_need) > 0]
set(EXPORTED_TO_ME_LIBRARIES 
  @asitems(libs_i_need)
  )
@[end if]
# swig_flags
@[if len(swig_flags) > 0]
set(EXPORTED_TO_ME_SWIG_FLAGS
  @asitems(swig_flags)
  )
@[end if]
# defines
@[if len(defines) > 0]
add_definitions(
  @asitems(defines)
  )
@[end if]
# recursive_depends
@[if len(recursive_depends) > 0]
add_dependencies(@(PROJECT)_gen_cpp 
  @asitems([x + "_gen_cpp" for x in recursive_depends])
  )
@[end if]



@[for pydir in pythondirs]
install(DIRECTORY @pydir/
  DESTINATION python
  COMPONENT @PROJECT
  PATTERN ".svn" EXCLUDE
  REGEX ".*\\.py$"
  )
@[end for]

@[if len(pythondirs) == 0 and (len(msgs) + len(srvs) > 0)]
install(FILES ${CMAKE_SOURCE_DIR}/cmake/__init__.py
  DESTINATION python/@PROJECT
  COMPONENT @PROJECT
  )
@[end if]


# includes_i_need
include_directories(
  @asitems(includes_i_need)
  )

# link_dirs
link_directories(
  @asitems(link_dirs)
  )

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DESTINATION share
  COMPONENT @PROJECT
  FILES_MATCHING 
  PATTERN "*.xml" 
  PATTERN "*.launch" 
  PATTERN "*.msg" 
  PATTERN "*.srv" 
  PATTERN "*.action" 
  PATTERN "*.cmake" 
  PATTERN "*.dox" 
  PATTERN "*.yaml" 
  PATTERN ".svn" EXCLUDE
  PATTERN "include" EXCLUDE
  )

install(EXPORT ROS NAMESPACE @PROJECT DESTINATION share/cmake)

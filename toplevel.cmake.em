#
#  this toplevel cmakelists was automatically generated
#
@{
def aslist(x):
    return ';'.join(x)
def asitems(x):
    return '\n  '.join(x)
def get(d, default, args):
    if len(args) == 0:
        return d
    if args[0] in d:
        return get(d[args[0]], default, args[1:])
    else:
        return default
}
@[for pkgname, d in packages.iteritems()]
set(@(pkgname)_PACKAGE_DIR @(d.attrib['srcdir']) CACHE FILEPATH "this should be SOURCE_DIR")
mark_as_advanced(@(pkgname)_PACKAGE_DIR)
set(@(pkgname)_SOURCE_DIR @(d.attrib['srcdir']) CACHE FILEPATH "this should be SOURCE_DIR")
mark_as_advanced(@(pkgname)_SOURCE_DIR)
set(@(pkgname)_SWIG_FLAGS "@(get(d, default="", args=('export', 'swig', 'flags')))" CACHE STRING "swig flags")
mark_as_advanced(@(pkgname)_SWIG_FLAGS)
set(@(pkgname)_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/@(pkgname)" CACHE INTERNAL "that pkg's binary dir")
@[end for]

@[for lang, path in langs.iteritems()]
message(STATUS " Language: @lang enabled.")
include(@path)
@[end for]

set(ROSBUILD_LANGS "@aslist(langs)" CACHE STRING "List of enabled languages")

include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.static.cmake)

#set(ROSBUILD_PYTHONPATH
#  @(':'.join(src_pythonpath))
#  )

macro(rosbuild_msgs)
@[for l in langs]
  genmsg_@(l[3:])(${ARGV})
@[end for]
endmacro()

macro(rosbuild_srvs)
@[for l in langs]
  gensrv_@(l[3:])(${ARGV})
@[end for]
endmacro()

macro(rosbuild_gentargets)
@[for l in langs]
  gentargets_@(l[3:])(${ARGV})
@[end for]
endmacro()

@[for pkg in topo_pkgs]
if(EXISTS @(packages[pkg].attrib['srcdir'])/CMakeLists.txt)
  add_subdirectory(@(packages[pkg].attrib['srcdir']) @(pkg))
endif()
@[end for]

#install(EXPORT ROS
#  FILE ros-exports.cmake
#  DESTINATION share/cmake
#  )

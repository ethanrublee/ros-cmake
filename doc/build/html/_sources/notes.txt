High level view/rationale
=========================

The build proceeds as follows:

* Walk the ROS_PACKAGE_PATH, read manifest.xml files, build an index.
  This happens without using rospack.  Build logic that needs to look
  at multiple packages uses this file, not rospack.  

* Sanitize the information in the index.  Some information in the
  manifests is in a format that is difficult to consume.

* Sanitize the CMakeLists.txt.  CMakeLists.txt contain certain
  invocations, for instance manual setting of RUNTIME_OUTPUT_DIR to be
  in the source directory, that must be removed.

* Generate cmake files.  A toplevel.cmake file is generated containing
  global information and a topologically sorted list of packages to
  traverse.  Each package contains a package.cmake file that contains
  e.g. information gleaned from manifest.xml files put in to a format
  that is convenient for cmake to consume.

Notes
=====

Build detritus
--------------

May **not** be placed in the source directory.  


Code Generators
---------------

Decoupling buildsystem components is one of the main goals of this
project.  This makes them more flexible and easier to use and debug.
Message generators are one of those.

In rosbuild2, the python library ``roslib`` has been split into two:
``roslib``, which may depend on the binary ``rospack``, and another,
``rosidl``, that may **not**.  Message generators use only ``rosidl``,
which parses message files and returns abstract syntax trees, to
generate libraries.

Message generator binaries must implement the following interface::

  generatorname <filename> -p <packagename> -o <outdir> -I<includepath1> -I<includepath2> ...

e.g. ::

  genmsg_cpp.py /ssd/wg/ros2/ros/core/roslib/msg/Header.msg  \
     -p roslib \
     -o /ssd/wg/ros2/build/gen/cpp \
     -I /ssd/wg/ros2/build/roslib \
     -I /ssd/wg/ros2/ros/tools/rospack \
     -I /ssd/wg/ros2/ros/core/roslib

where **filename** is the absolute path to the message file,
**packagename** is the name of the package in which the message
resides, **outdir** is the directory to which to write the results,
and the **includepath** arguments specify a search path for code that
**filename** may include, e.g. nested message types.

This is all the information a code generator needs to do its job.



Subshelling and environment variables
-------------------------------------

Environment variables are globals, and globals are to be avoided.  The
build must work without any particular environment variables being
set, as all information necessary to build is encoded in
CMakeCache.txt and makefiles at generation time.

To achieve this the build system freeze-dries the correct environment
in a script ``env.sh`` that is used to set the environment for any
subshells that are executed, only for the duration of that subshell,
via the cmake variable ``ROSBUILD_SUBSHELL``.






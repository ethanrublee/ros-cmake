.. _thirdparty:

Third party software
====================

A preprequisite to building various ros packages is third party
software.  This has been moved out of the 'regular' ros build to an
external area.  The code to build/isntall third party stuff is now at
  
* `<http://github.com/straszheim/ros-3rdparty>`_

Third party packages must do the following:

* Install independently of rosbuild and rospack to some designated
  (possibly user-specified) area which we'll call ``$THIRDPARTY``, by
  default ``/opt/ros/DISTRO/3rdparty``.  

* Provide cmake infrastructure: for 3rdparty package ``thirdparty``, a
  cmake script ``thirdpartyConfig.cmake`` under
  ``$THIRDPARTY/share/cmake/<thirdparty>/`` (see cmake documentation
  for ``find_package`` in "config" mode) for details on how cmake
  finds and uses these files.

With this accomplished, the interface between rosbuild and these
3rdparty packages is cmake's ``find_package()``.  ROS's build system
gains flexibility including future possibilites to:

* Moving these dependencies out to e.g. robotpkg.
* Have these 3rdparty packages downloaded-patched-built-installed from
  source rosdep.
* Ability for maintainers of e.g. Windows or Android ports to maintain
  3rdparty ports independently, so long as they provide the minimal
  cmake infrastructure mentioned above.

The existing 3rdparty setup is quick-and-dirty pending decisions on
how exactly to Do It right.  The script
`<https://github.com/straszheim/ros-cmake/raw/master/thirdparty_install_from_scratch.sh>`_
shows how.


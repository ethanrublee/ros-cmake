.. _thirdparty:

Third party software
====================

A preprequisite to building various ros packages is third party
software.  This has been moved out of the 'regular' ros build to an
external area.  The code to build/install this stuff is now at
  
* `<http://github.com/straszheim/ros-3rdparty>`_

Third party packages must do the following:

* Install independently of rosbuild and rospack (but not rosdep) to
  some designated (possibly user-specified) area which we'll call
  ``$THIRDPARTY``, by default ``/opt/ros/DISTRO/3rdparty``.

* Provide cmake infrastructure: for 3rdparty package ``thirdparty``, a
  cmake script ``thirdparty-config.cmake`` under
  ``$THIRDPARTY/share/cmake/<thirdparty>/``.  See cmake documentation
  for ``find_package`` (in `config` mode) for details on how cmake finds
  and uses these files.

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


CMake infrastructure tips
-------------------------

CMake's readme for cmake Modules:
`<http://cmake.org/gitweb?p=cmake.git;a=blob;f=Modules/readme.txt>`_. 

With the exception of keeping the cache clean: set XXX_INCLUDE_DIRS,
XXX_LIBRARIES and XXX_DEFINITIONS in the cache.

For 3rdparty package ``THIRD``, file ``third-config.cmake`` is
responsible for defining several variables which must be in the cache,
(so that developers can redirect them when e.g. chasing bugs or
testing upgrades).  The package name should be in lowercase in the
filename, uppercase in the names of variables that it sets.  For example, file 
``kdl-config.cmake``::

  find_path(KDL_INCLUDE_DIRS
    kdl/kdl.hpp  
    PATHS /opt/ros/unstable/3rdparty/kdl/include
    NO_DEFAULT_PATH
    )
  
  set(KDL_DEFINITIONS "" CACHE STRING "kdl definitions")
  
  find_library(KDL_LIBRARIES 
    orocos-kdl
    PATHS /opt/ros/unstable/3rdparty/kdl/lib
    NO_DEFAULT_PATH
    )
  
  if (KDL_INCLUDE_DIRS AND KDL_LIBRARIES) 
    set(KDL_FOUND TRUE) 
  endif()
  
We use ``find_library`` and ``find_path``, despite the fact that we
know where things are.  These will set variables to
``varname-NOTFOUND`` if they don't find things.  Cmake knows how to
handles this, and cmake users will be familiar with what this means.
It gives an extra check that at least a few things are installed
correctly, and it creates cache variables so that developers can
modify them e.g. when testing new versions of 3rdparty packages.

.. rubric:: Open questions

* Install to individual package directories or one directory?  This
  has implications for LD_LIBRARY_PATH and/or rpaths.

* What does the rosdep interface look like exactly?

* Macports would install these thirdparty packages (using DESTDIR) to
  a cache location (``$prefix/var/cache`` I think) and then create
  hardlinks, which makes uninstall/deactivate operations easier.  I've
  dreamed of a pure python macports on previous projects that also
  involved maintaining repositories of 3rdparty packages.

* Integration with 'robotpkg' or the like?  It sure would be nice if
  this tool were somehow ROS-neutral, if that would help it attract
  more users.


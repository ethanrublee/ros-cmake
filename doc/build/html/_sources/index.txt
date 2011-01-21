.. ros-cmake documentation master file, created by
   sphinx-quickstart on Mon May 11 08:53:19 2009.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


Code
----

ros-cmake is in the 'ros-cmake' repository at
https://github.com/straszheim/ros-cmake.  The git clone url is
``git://github.com/straszheim/ros-cmake.git``.  Don't run off and
clone it yet; use the walkthrough.  But **dont do this yet**, follow
the directions below.


Just Run It
-----------

Just Type This::

   mkdir tmp
   cd tmp
   wget --no-check-certificate https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall
   rosinstall -n $WORK ros-cmake.rosinstall
   ./cmake/run_full_build.sh

See the `walkthrough` for  more details.


Contents
--------

.. toctree::
   
   walkthrough
   notes

.. ros-cmake documentation master file, created by
   sphinx-quickstart on Mon May 11 08:53:19 2009.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


Code
====

ros-cmake is in the 'ros-cmake' repository at
https://github.com/straszheim/ros-cmake.  The git clone url is
``git://github.com/straszheim/ros-cmake.git``.  But **dont do this
yet**, follow the directions below.


Quickstart
==========

Eventually these will be the fanciest of docs.  For the moment they
are only a list of "here's how to try it out" commands.  These are the
same commands run by the script ``fromscratch.sh`` in the ros-cmake
project.  You should be able to copy-paste these from this webpage
verbatim.

Setup build environment
-----------------------

* Pull down the rosinstall file::

    wget --no-check-certificate  https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

* Pick a directory to work in.  I'll assume this is called ``work``.

* Do the rosinstall thing, use the ``-n`` flag to have it only check
  things out.  We will need to refer to our work directory, let's set
  this in an environment variable::

    export WORK=`pwd`/work

  and run rosinstall to check things out (only) to ``$WORK``::

    rosinstall -n $WORK ros-cmake.rosinstall

* cd in there::

    cd $WORK

* At this point your environment should be clean... no rosness, no
  ``ROS_ROOT``.  There is a script called ``doit.sh`` in the ``cmake``
  directory that we'll be walking through.  

* Create a stub toplevel ``CMakeLists.txt`` that includes
  ``cmake/main.cmake``.  It should contain only::

    cmake_minimum_required(VERSION 2.8)
    include(cmake/main.cmake)

Modify buildspace
-----------------

* Remove some stuff that hasn't been converted yet.  This is to 'hide'
  it from ros-cmake::

    rm ros_comm/clients/roslisp/manifest.xml
    rm -rf ros/core/rosbuild
    rm -rf ros/core/mk

* Now apply a bunch of patches to the build tree.  They are stored in
  a subdirectory ``patches`` of cmake::

    rsync -a ./cmake/patches/ $WORK/

  **watch your slashes there**, if that command isn't executed
  verbatim it will do something that is probably not what we want.

* Now the (black) magic starts.  First we'll need to extract the
  ``ROS_PACKAGE_PATH`` from the rosinstall-generated ``setup.sh``
  (bash syntax), **and append the ros stack**::

    # set ROS_PACKAGE_PATH in your environment
    `grep ROS_PACKAGE_PATH setup.sh`  

    # append to it
    ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$WORK/ros

    echo $ROS_PACKAGE_PATH 
    /tmp/work/driver_common:/tmp/work/diagnostics:/tmp/work/rx:/tmp/work/common_tutorials:/tmp/work/ros_tutorials:/tmp/work/geometry:/tmp/work/common_msgs:/tmp/work/common:/tmp/work/ros_comm:/tmp/work/rosidl:/tmp/work/cmake:/tmp/work/ros
  
* Now run ``build_index.py`` to create an "index" (just a pickled
  python dictionary) of what is in the buildspace.  The first argument
  is the name of the file to create, which we will refer to later::

    $ ./cmake/build_index.py index.pkl $ROS_PACKAGE_PATH
    Building index of packages in /tmp/work/driver_common:/tmp/work/diagnostics:/tmp/work/rx:/tmp/work/common_tutorials:/tmp/work/ros_tutorials:/tmp/work/geometry:/tmp/work/common_msgs:/tmp/work/common:/tmp/work/ros_comm:/tmp/work/rosidl:/tmp/work/cmake:/tmp/work/ros

  You can have a quick look at what is in there::

    $ ./cmake/show_index.py index.pkl | less

    Index@ sys.argv[1]:
    
    {('actionlib', None): {'actions': ['action/TwoInts.action',
                                       'action/Test.action'],
                           'author': 'Eitan Marder-Eppstein, Vijay Pradeep',
                           'brief': 'Provides a standardized interface for a task',
                           'cfgs': [],
                           'depend': ['roscpp',
                                      'rospy',
                                      'rostest',
                                      'actionlib_msgs'],
    (etc etc)

  at this point it has not been 'sanitized' yet... it is not in a form
  consumable by the rest of the procedure.  One way to think about
  what has happened here is that 'rospack' has been run with all
  possible arguments on all available projects, and the results have
  been stored in an index.

* Sanitize the ``manifest.xml`` bits::

    $ ./cmake/sanitize_manifest.py index.pkl
    * Expanding backticks
    * removing ${prefix}
    * parsing and reorganizing compiler flags
    Generating full recursive dependencies
    >>>                    test_rxdeps
           
  Now there are new fields in the index.pkl containing e.g. expanded
  backticks and replaced ${prefix} variables.

* Sanitize the assorted CMakeLists.txt.  This modifies the source
  tree; at some point this will have to go away, presumably after
  we've decided what the new CMakeLists.txt will actually look like::

    $ ./cmake/sanitize_cmakelists.py -i index.pkl
    Sanitizing cmakelists from index index.pkl

  Among other things, this script has removed
  ``set(EXECUTABLE_OUTPUT_PATH ...)``, ``rosbuild_init()``, and
  various other incantations found in every cmakelistss that are no
  longer necessary.

* Now you'll see those CMakeLists.txt modifications::

    $ cd ros
    $ svn status
    M       test/test_rosmake/CMakeLists.txt
    M       test/test_rospack/CMakeLists.txt
    M       test/test_roscreate/CMakeLists.txt
    M       test/test_roslib/CMakeLists.txt
    M       test/test_rosdep/CMakeLists.txt
    ?       tools/rosbash/CMakeLists.txt
    M       tools/rosmake/CMakeLists.txt
    M       tools/rospack/CMakeLists.txt
    M       tools/rosunit/CMakeLists.txt
    M       tools/rosclean/CMakeLists.txt
    M       tools/roscreate/CMakeLists.txt
    ?       tools/rosboost_cfg/CMakeLists.txt
    ?       tools/rosdep/CMakeLists.txt
    ?       tools/rosemacs/CMakeLists.txt
    !       core/rosbuild
    ?       core/roslang/CMakeLists.txt
    !       core/mk
    M       core/roslib/CMakeLists.txt
    
  Some new files have been created, some modified, a couple others
  were deleted earlier.

* In this last step we clobbered a few CMakeLists.txt that we rsynced
  onto the build tree earlier.  Do it again::

    $ cd $WORK  # $WORK == the directory created by rosinstall
    $ rsync -a ./cmake/patches/ $WORK/

Generate CMakeLists.txt and run cmake
-------------------------------------

* Make a build directory and generate a ton of cmake stuff::

    $ mkdir build
    $ ./cmake/generate_cmakelists.py index.pkl build ./cmake

    Index@ sys.argv[1]:

    LANGS= {'rospy': '/tmp/work/ros_comm/clients/rospy/cmake/rospy.cmake', 'roscpp': '/tmp/work/ros_comm/clients/cpp/roscpp/cmake/roscpp.cmake'}
    >>> tf_conversions                     

  in ``build/`` you will now see a file ``toplevel.cmake``, which sets
  a bunch of variables and, importantly, controls the order with which
  cmake will traverse package directories.  There are also
  subdirectories, one per package, each containing a file
  ``package.cmake`` which contains cmake code generated from
  ``manifest.xml`` files, among other things.

* Run cmake (see warning box in output below)::

    $ cd build
    $ cmake -DCMAKE_INSTALL_PREFIX=/tmp/installdir ..

    -- --- main.cmake ---
    -- Boost version: 1.40.0
    -- Found the following Boost libraries:
    --   date_time
    --   filesystem
    --   graph
    --   iostreams
    --   math_c99
    --   math_tr1
    --   prg_exec_monitor
    --   program_options
    --   python
    --   regex
    --   serialization
    --   signals
    --   system
    --   thread
    --   unit_test_framework
    --   wave
    --   wserialization
    --  * rospy
    --  * roscpp
      ROSBUILD_LANGS = rospy;roscpp
    *
    *
    * building eigen
    *
    *
    --2011-01-12 06:28:19--  http://pr.willowgarage.com/downloads/eigen2-2.0.15.tar.bz2
    Resolving pr.willowgarage.com... 157.22.19.18
    Connecting to pr.willowgarage.com|157.22.19.18|:80... connected.
    
  .. warning::

     You'll see a *lot* of stuff happen here, mostly
     the building of 3rdparty dependencies: eigen, smclib, bullet,
     orocos-kdl, wxswig.  It won't stay this way.  

  At the end you'll see the traversal of the ROS packages...

  ::

    -- 3rdparty kdl bootstrap returned 0.  Good.
     --  + test_rostest
     --  + topic_tools
     --  + rosbag
     --  + test_roscpp
     --  + test_rosnode
     --  + test_rosbag
     --  + rosmsg
     --  + rosbagmigration
     --  + rosrecord
     --  + rxbag
     --  + roscore_migration_rules
     --  + geometry_msgs
     --  + tf_core
     --  + diagnostic_msgs
     --  + runtime_monitor
     --  + rostopic
     --  + visualization_msgs
     --  + rosservice
     --  + test_rosmsg
     --  + test_rostopic
     --  + diagnostic_analysis
     --  + test_rospy
     --  + test_rosservice
     --  + tf_cpp
     --  + nav_msgs
     --  + diagnostic_aggregator
     --  + sensor_msgs
     --  + test_diagnostic_aggregator
     --  + roswtf
     --  + dynamic_reconfigure
     MSG: gencfg_cpp on:cfg/Test.cfg
     --  + rxgraph
     --  + test_topic_tools
     tf /tmp/work/geometry/tf /tmp/work/build/tf
     --  + tf
     -- Performing Test HAS_SSE3_EXTENSIONS
     -- Performing Test HAS_SSE3_EXTENSIONS - Success
     -- Performing Test HAS_SSE2_EXTENSIONS
     -- Performing Test HAS_SSE2_EXTENSIONS - Success
     -- Performing Test HAS_SSE_EXTENSIONS
     -- Performing Test HAS_SSE_EXTENSIONS - Success
     -- [rosbuild] Found SSE3 extensions, using flags: -msse3 -mfpmath=sse
     --  + diagnostic_updater
     --  + robot_monitor
     --  + self_test
     --  + eigen_conversions
     --  + driver_base
     --  + test_common_msgs
     --  + test_roswtf
     --  + tf_conversions
     *** fixme, install of ros/bin/
     -- Configuring done
     -- Generating done
     -- Build files have been written to: /tmp/work/build
   
  If you see the last line, ``Build files have been written to: ...``,
  you may briefly rejoice.

Build
-----

Now you can build.  Optionally use ``-jN`` where N is one greater than
the number of cores you have on the machine.  ``ROS_PARALLEL_JOBS`` is
ignored. ::

  $ make -j9
  Scanning dependencies of target xmlrpcpp_gen_cpp
  [  0%] Built target xmlrpcpp_gen_cpp
  Scanning dependencies of target XmlRpc
  [  0%] Building CXX object xmlrpcpp/CMakeFiles/XmlRpc.dir/src/XmlRpcClient.cpp.o
  [  0%] Building CXX object xmlrpcpp/CMakeFiles/XmlRpc.dir/src/XmlRpcDispatch.cpp.o

  ... lots of stuff ...

  [100%] Built target run_selftest
  [100%] Built target selftest_example
  [100%] Built target selftest_rostest

Output will be jumbled due to the -j.  Now type make again and behold
the speed with which it tells you that there is nothing to do.

All build artifacts are in the build directory.  Generated code is
under ``gen/<LANG>``.  Notice the generated ``__init__.py`` scripts
under ``gen/py/*`` that extend the search path back to the static
source directories.  These disappear on installation.

Note also the generated ``env.sh`` script that contains environment
settings approriate to this buildspace.


Use
---

Now you should be able to use a few things, from the build directory.
Starting from a completely clean environment (note that so far in the
process we have defined **no** environment variables whatsoever), run
the ``env.sh`` script::

  % ./env.sh 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %                                                                                      %
  %                              ROS: Robot Operating System                             %
  %                                                                                      %
  %                                       Version                                        %
  %                                                                                      %
  %                            Visit us at http://www.ros.org                            %
  %                                                                                      %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  ROS environment has:
     ROS_ROOT       = /home/ros2/ros
     ROS_BUILD      = /home/ros2/build
     ROS_MASTER_URI = http://localhost:11311
    
Yes, the little banner is gratuitous, but I had the code laying
around.  This will spawn a subshell; your ``.bashrc`` ought not
clobber your environment variables.  

.. todo:: a version that you just 'source'.  This is impervious to
   	  whatever shenanigans might be found in your ``bashrc``.

Now run roscore::

  % roscore
  ... logging to /u/straszheim/.ros/log/319a5fe0-2434-11e0-9ce0-003048fd853e/roslaunch-hpy-31830.log
  Checking log directory for disk usage. This may take awhile.
  Press Ctrl-C to interrupt
  Done checking log file disk usage. Usage is <1GB.
  
  started roslaunch server http://hpy:35220/
  
  SUMMARY
  ========
  
  NODES
  
  auto-starting new master
  process[master]: started with pid [31845]
  ROS_MASTER_URI=http://hpy:11311/
  
  setting /run_id to 319a5fe0-2434-11e0-9ce0-003048fd853e
  process[rosout-1]: started with pid [31875]
  started core service [/rosout]
  
Open another terminal, source the env.sh, run the talker demo::

  % ./bin/talker 
  [ INFO] [1295486800.693401647]: hello world 0
  [ INFO] [1295486800.793485151]: hello world 1
  [ INFO] [1295486800.893499308]: hello world 2
  ...

Install
-------

Just 'make install'.  Things will get installed to the
``CMAKE_INSTALL_PREFIX`` specified when you ran CMake.

::

  % make install
  [lots of stuff]
  -- Installing: /home/ros2/inst/share/cmake/ROS.cmake
  -- Installing: /home/ros2/inst/share/cmake/ROS-noconfig.cmake

Use
--- 

Using the installed version is the same as the buildspace version,
above, modulo that the ``env.sh`` script is in the ``bin`` directory.



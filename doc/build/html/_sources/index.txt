.. ros-cmake documentation master file, created by
   sphinx-quickstart on Mon May 11 08:53:19 2009.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


Code
====

ros-cmake is in the 'ros-cmake' repository at
https://github.com/straszheim/ros-cmake.  The git clone url is
``git@github.com:straszheim/ros-cmake.git``.


Quickstart
==========

Eventually these will be the fanciest of docs.  For the moment they
are only a list of "here's how to try it out" commands.  These are the
same commands run by the script ``fromscratch.sh`` in the ros-cmake

* Pull down the rosinstall file::

    wget --no-check-certificate  https://github.com/straszheim/ros-cmake/raw/master/ros-cmake.rosinstall

* Pick a directory to work in.  I'll assume this is called ``work``.

* Do the rosinstall thing, use the ``-n`` flag to have it only check
  things out.  Why is this thing called rosinstall? ::

    rosinstall -n work ros-cmake.rosinstall

* cd in there::

    cd work

* At this point your environment should be clean... no rosness, no
  ``ROS_ROOT``.  There is a script called ``doit.sh`` in the ``cmake``
  directory that we'll be walking through.  

* Create a stub toplevel ``CMakeLists.txt`` that includes
  ``cmake/main.cmake``.  It should contain only::

    cmake_minimum_required(VERSION 2.8)
    include(cmake/main.cmake)

* Remove some stuff that hasn't been converted yet.  This is to 'hide'
  it from ros-cmake::

    rm ros_comm/clients/roslisp/manifest.xml
    rm -rf ros/core/rosbuild
    rm -rf ros/core/mk

* Now apply a bunch of patches to the build tree.  They are stored in
  a subdirectory ``patches`` of cmake::

    rsync -a ./cmake/patches/ ./

  **watch your slashes there**, if that command isn't executed
  verbatim it will do something that is probably not what we want.

* Now the (black) magic starts.  First we'll need to extract the
  ``ROS_PACKAGE_PATH`` from the rosinstall-generated ``setup.sh``
  (bash syntax), **and append the ros stack**::

      $ $(grep ROS_PACKAGE_PATH setup.sh)
      $ ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:`pwd`/ros
      $ echo $ROS_PACKAGE_PATH 
      /tmp/work/driver_common:/tmp/work/diagnostics:/tmp/work/rx:/tmp/work/common_tutorials:/tmp/work/ros_tutorials:/tmp/work/geometry:/tmp/work/common_msgs:/tmp/work/common:/tmp/work/ros_comm:/tmp/work/rosidl:/tmp/work/cmake:/tmp/work/ros
  
* Now run ``build_index.py`` to create an "index" (just a pickled
  python dictionary) of what is in the buildspace.  The first argument
  is the name of the file to create, which we will refer to later::

    % ./cmake/build_index.py index.pkl $ROS_PACKAGE_PATH
    Building index of packages in /tmp/work/driver_common:/tmp/work/diagnostics:/tmp/work/rx:/tmp/work/common_tutorials:/tmp/work/ros_tutorials:/tmp/work/geometry:/tmp/work/common_msgs:/tmp/work/common:/tmp/work/ros_comm:/tmp/work/rosidl:/tmp/work/cmake:/tmp/work/ros

  You can have a quick look at what is in there::

    % ./cmake/show_index.py index.pkl | head -20

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
  consumable by the rest of the procedure.

* Sanitize the ``manifest.xml`` bits::

    % ./cmake/sanitize_manifest.py index.pkl
    Sanitizing manifest index...
    Generating full recursive dependencies
    r:                                        test_rxdeps
        
  Now there are new fields in the index.pkl containing e.g. expanded
  backticks and replaced ${prefix} variables.

* Sanitize the assorted CMakeLists.txt.  This modifies the source
  tree; at some point this will have to go away, presumably after
  we've decided what the new CMakeLists.txt will actually look like::

    $ ./cmake/sanitize_cmakelists.py -i index.pkl
    Sanitizing cmakelists from index index.pkl

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
    $ rsync -a ./cmake/patches/ ./

* Make a build directory and generate a ton of cmake stuff::

    $ mkdir build
    $ ./cmake/generate_cmakelists.py index.pkl build ./cmake

    Index@ sys.argv[1]:

    LANGS= {'rospy': '/tmp/work/ros_comm/clients/rospy/cmake/rospy.cmake', 'roscpp': '/tmp/work/ros_comm/clients/cpp/roscpp/cmake/roscpp.cmake'}
    >>> tf_conversions                     

  in ``build/`` you will now see a file ``toplevel.cmake``, which sets
  a bunch of variables and most importantly controls the order with
  which cmake will traverse package directories.  There are also
  subdirectories, one per package, each containing a file
  ``package.cmake`` which contains cmake code generated from
  ``manifest.xml`` files, among other things.

* Run cmake::

    $ cd build
    $ cmake -DROS_BUILD_SHARED_LIBS=TRUE -DCMAKE_INSTALL_PREFIX=/tmp/installdir ..

  You'll see a *lot* of stuff happen during the cmake run, especially
  the building of 3rdparty dependencies: eigen, smclib, bullet,
  orocos-kdl.  This is to be somehow fixed later.::

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
   
  If you see the `Build files have been written` bit, rejoice.  

* Now you can build::

    $ make
    Scanning dependencies of target xmlrpcpp_gen_cpp
    [  0%] Built target xmlrpcpp_gen_cpp
    Scanning dependencies of target XmlRpc
    [  0%] Building CXX object xmlrpcpp/CMakeFiles/XmlRpc.dir/src/XmlRpcClient.cpp.o
    [  0%] Building CXX object xmlrpcpp/CMakeFiles/XmlRpc.dir/src/XmlRpcDispatch.cpp.o

    ... lots of stuff ...

    [100%] Built target run_selftest
    [100%] Built target selftest_example
    [100%] Built target selftest_rostest




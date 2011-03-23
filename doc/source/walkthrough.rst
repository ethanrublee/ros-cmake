.. _walkthrough:

Walkthrough
===========

Here's how to make it go.  Many of these steps will not be necessary
in the finished product.  The commands below are the same as those run
by the script `run_full_build.sh
<https://github.com/straszheim/ros-cmake/raw/master/run_full_build.sh>`_
in the ros-cmake project.

You should be able to copy-paste the commands below into your terminal
verbatim.

Install 3rdparty packages
-------------------------

See :ref:`thirdparty`.  


Setup build environment
-----------------------

* Pull down the rosinstall file::

    wget --no-check-certificate  https://github.com/straszheim/ros-cmake/raw/master/rosinstalls/ros-cmake.rosinstall

* Pick a directory to work in.  I'll assume this is called
  ``work``. We will need to refer to our work directory, let's set
  this in an environment variable::

    export WORK=`pwd`/work

* Do the rosinstall thing, use the ``-n`` flag to have it only check
  things out.::

    rosinstall -n $WORK ros-cmake.rosinstall

* load the setup.sh file::

    . $WORK/setup.zsh   # or bash, as appropriate.

* make a build directory::

    mkdir build

* cd in there and run cmake::

    cd build
    cmake ../work

  you should see lots of output::

    % cmake ../work
    -- The C compiler identification is GNU
    -- The CXX compiler identification is GNU
    -- Check for working C compiler: /home/troy/bin/gcc
    -- Check for working C compiler: /home/troy/bin/gcc -- works
    -- Detecting C compiler ABI info
    -- Detecting C compiler ABI info - done
    -- Check for working CXX compiler: /home/troy/bin/c++
    -- Check for working CXX compiler: /home/troy/bin/c++ -- works
    -- Detecting CXX compiler ABI info
    -- Detecting CXX compiler ABI info - done
    -- --- main.cmake ---
    
    Generating cmake
    
    -  convex_decomposition
    -  robot_state_publisher
    -  colladadom
    -  ivcon

  in this section, lines starting with a dash are projects that have
  not been converted (i.e. do not contain a 'rosbuild2' section in
  their manifests).

  ::

    -  rosemacs
    +  rospack
    -  rosboost_cfg
    
    Writing toplevel for 34 packages....
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
    -- Looking for include files CMAKE_HAVE_PTHREAD_H
    -- Looking for include files CMAKE_HAVE_PTHREAD_H - found
    -- Looking for pthread_create in pthreads
    -- Looking for pthread_create in pthreads - not found
    -- Looking for pthread_create in pthread
    -- Looking for pthread_create in pthread - found
    -- Found Threads: TRUE 
    -- Performing Test HAS_SSE3_EXTENSIONS
    -- Performing Test HAS_SSE3_EXTENSIONS - Success
    -- Performing Test HAS_SSE2_EXTENSIONS
    -- Performing Test HAS_SSE2_EXTENSIONS - Success
    -- Performing Test HAS_SSE_EXTENSIONS
    -- Performing Test HAS_SSE_EXTENSIONS - Success
    -- Found SSE3 extensions, using flags: -msse3 -mfpmath=sse
    --  Language: rospy enabled.
    --  Language: roscpp enabled.
    --  + rosconsole
    --  + rospack
    --  + stereo_msgs
    --  + actionlib_msgs
    --  + trajectory_msgs
    --  + nav_msgs
    --  + roscpp
    -- Looking for include files HAVE_IFADDRS_H
    -- Looking for include files HAVE_IFADDRS_H - found
    -- Looking for trunc
    -- Looking for trunc - not found
    --  + actionlib
    --  + roslib
    --  + roscpp_serialization
    --  + roscpp_traits
    --  + topic_tools
    --  + rostest
    --  + visualization_msgs
    --  + cpp_common
    -- Looking for execinfo.h
    -- Looking for execinfo.h - found
    -- Performing Test HAVE_CXXABI_H
    -- Performing Test HAVE_CXXABI_H - Failed
    -- Looking for backtrace
    -- Looking for backtrace - found
    --  + dynamic_reconfigure
    --  + message_filters
    --  + rostime
    --  + sensor_msgs
    --  + roswtf
    --  + rosservice
    --  + rospy
    --  + roscpp_tutorials
    --  + std_msgs
    --  + diagnostic_msgs
    --  + rosgraph_msgs
    --  + test_roscpp
    --  + std_srvs
    --  + xmlrpcpp
    --  + geometry_msgs
    --  + turtlesim
    -- Found wxWidgets: TRUE 
    --  + rosbag
    *** fixme, install of ros/bin/
    -- Configuring done
    -- Generating done
    -- Build files have been written to: /home/glom/build
    

Build
-----

Now you can build.  Optionally use ``-jN`` where N is one greater than
the number of cores you have on the machine.  ``ROS_PARALLEL_JOBS`` is
ignored. ::

    % make
    Scanning dependencies of target cpp_common_gen_cpp
    [  0%] Built target cpp_common_gen_cpp
    Scanning dependencies of target cpp_common
    [  0%] Building CXX object cpp_common/CMakeFiles/cpp_common.dir/src/debug.cpp.o
    Linking CXX shared library ../lib/libcpp_common.so
    [  0%] Built target cpp_common
    Scanning dependencies of target rostime_gen_cpp
    [  0%] Built target rostime_gen_cpp
    Scanning dependencies of target rostime
    [  0%] Building CXX object rostime/CMakeFiles/rostime.dir/src/time.cpp.o
    [  0%] Building CXX object rostime/CMakeFiles/rostime.dir/src/rate.cpp.o
    [  1%] Building CXX object rostime/CMakeFiles/rostime.dir/src/duration.cpp.o
    
Once the build is finished, type make again and behold the speed with
which it tells you that there is nothing to do.::

    % /usr/bin/time make -j8
    <lots of output>
    5.24user 0.79system 0:00.41elapsed 1442%CPU (0avgtext+0avgdata 19280maxresident)k
    0inputs+672outputs (0major+333398minor)pagefaults 0swaps

0.4 seconds elapsed.

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

In another, run the listener..::

  % ./bin/listener
  [ INFO] [1300849344.814661724]: I heard: [hello world 3]
  [ INFO] [1300849344.914395490]: I heard: [hello world 4]
  [ INFO] [1300849345.014413543]: I heard: [hello world 5]

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



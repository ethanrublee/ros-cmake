gen_cmake.py
============

Does the business of generating cmake files.  This is because
scripting in cmake is so painful... easier to just generate the the
damned things.  Really cmake itself should just be a python api.


First argument is the pythonpath for roslib, etc.  Second argument is
the pythonpath for the file that contains interproject dependencies.



cmake variables
===============

ROS_ROOT aka CMAKE_SOURCE_DIR
ROS_BUILD aka CMAKE_BINARY_DIR

ROSPACK_EXE   relative to ROS_BUILD, determined by bootstrap procs
ROSSTACK_EXE

ROSLIB_PYPATH  relative to ROS_ROOT... determined by layout of SVN

ROSBOOST_CFG   python boost-detecting binary... determined by layout of SVN

ROSBUILD_ROOT  relative to ROS_ROOT... determined by layout of svn



setup.sh enhancements
=====================

can exit the subshell and use as env-setter



generator cmake exports
=======================

still need to figure out what the right interface is for these guys
and how to keep targets clean



code generators
===============

code generators convert .msg files into one or more files in some
target language.  Currently the dependence on environment variables
and positional arguments adds complexity to the build system.  Their
interface is::

  generatorprog --message=/absolute/path/to/File.msg --outdir=/destination/dir

They must be able to accept the 'input' and 'outdir' arguments in
either order, and they must ignore (???) unknown options.



system dependencies
===================

should be detected with find_package, either cmake-supplied or
homebrewed.  ``find_file``, ``find_library`` and ``try_compile``
should be used to verify that the system dependency has been found
properly and can actually be compiled/linked against.

At this point several variables will have been set::  

  dep_LIBRARIES
  dep_INCLUDE_DIRS
  dep_CFLAGS
  dep_LDFLAGS
  
of particular interest to us is dep_LIBRARIES.  This will contain a
list of *full* paths to libraries... not flags like -Lfoo.  CMake is
smart enough to link lines and rpaths correctly when building and
installing without our help.  So the desired call is

   target_link_libraries(mytarget  /abspath/to/libsomething.so)


the 'core/mk' project
=====================

as far as I can tell is unnecessary and can be deleted



calling ``execute_process`` from cmake
======================================

again the dependencies on environment and argument ordering make the
operation of these scripts opaque.  Call them with explicit
environment and long command options::

  /usr/bin/env ENV1=value1 ENV2=value2 myscript --arg1name=arg1value --arg2name=arg2value

also check RESULT_VARIABLE:

if(res)
  message(FATAL_ERROR "egh")
endif()		



dont fill parenthesis in endif/endforeach/endmacro
==================================================

cmake will complain if these are filled in and they don't match, 
otherwise it will be happy and do the correct thing.

if(SOMETHING)
  add_library(...)
endif()    # <- no SOMETHING thank you



etc
===

no script may write to any directory other than its --outdir argument.


verbosity
=========

if you ``make VERBOSE=1``, make sets VERBOSE equals 1 in the
environment of the commands that it shells out to, often like this::

  some_command arg1 arg2 --verbose=$(VERBOSE)

To intergrate nicely, programs executed by the build should accept an
argument --verbose= with the following behavior:

no argument -- prints no additional information
1  -- prints at most one line of additional information per invocation
2  -- may print several lines indicating which files are being read and written
3  -- may be annoyingly chatty

Yes, this isn't typical commandline behavior, but these are utility
scripts for use by cmake.

cmake code that calls out to python in custom targets should pass the
argument ${ROSBUILD_VERBOSE}, e.g.::

  add_custom_command(OUTPUT somefile
    COMMAND ${ROSBUILD_SUBSHELL}
    script_to_run.py
    arg1 arg2 ${arg3}
    ${ROSBUILD_VERBOSE}
    )

Which on unix itself expands to ``--verbose=$$VERBOSE``, i.e. makes
use of the environment variable VERBOSE which can be set by the user
on the ``make`` commandline or in some other convenient way.

ROSBUILD_VERBOSE also gives us a single customization point for use
under windows.


manifest.xml
============

- no shellouts
- explicit includes

the exports in the manifests often have dependencies on a shell
environment for things like lflags=`

why .xml instead of yaml?


globs
=====

any globbing must be done at cmake generation time, i.e. either in
cmake-language itself or in python scripts that generate cmake code,
so that dependencies can be fully expressed to cmake.


usecases
--------


python: must generate an __init__.py that contains includes for the
various messages in the current subdirectory



- when this is changed and two versions are in play, how to handle
  that the only docs are on the wiki


caching
=======

Two considerations:

#. caching adds complexity
#. cmake generation doesn't happen very often

so avoid complicated caching schemes.  Let the data have one canonical
representation.  Carefully transform it into whatever is currently
needed.

oh god
======

roslua, for instance, finds the .msg files on its own when it starts
up.  How does it do this, what is it tangled in to?



shell code in ros/rosdep.yaml:

log4cxx:
  ubuntu:
    '10.04': liblog4cxx10-dev
    '9.10': liblog4cxx10-dev
    '9.04': liblog4cxx10-dev
    '8.10': |
      if [ ! -f /opt/ros/lib/liblog4cxx.so.10 ] ; then
        mkdir -p ~/ros/ros-deps
        cd ~/ros/ros-deps
        wget --tries=10 http://pr.willowgarage.com/downloads/apache-log4cxx-0.10.0-wg_patched.tar.gz
        tar xzf apache-log4cxx-0.10.0-wg_patched.tar.gz
        cd apache-log4cxx-0.10.0
        ./configure --prefix=/opt/ros
        make
        sudo make install
      fi
    '8.04': |
      if [ ! -f /opt/ros/lib/liblog4cxx.so.10 ] ; then



For users
=========

How to update your project
--------------------------





How to use the same workflows with the new system
-------------------------------------------------



packages vs. 'tools'
--------------------

log4cxx, cuda, gtest... rospack?
bootstrap these once, possibly make .debs for the whole 



-- check for circular dependencies in packages


bad things currently in cmakelists
----------------------------------

cmake_minimum_required  -- goes at toplevel only

set(EXECUTABLE_OUTPUT_DIR ...)

set(LIBRARY_OUTPUT_DIR ...)




-- new setup.sh scripts, can set and check the environement in such a
   way that it is exitable, gives a single point of environment for
   dev/install/and build processes

-- these should be: spawner script checks for env variables and sets
   ROS_ENVIRONMENT in env, spawns subshell.  users modify subshell
   to check and source ROS_ENVIRONMENT if available



-- if you need to do temporary work do it in 

      ${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}



"practice good buildsystem hygiene"


ROS_HOME:  ~/.ros contains stuff


installed stack(s),   one stack in development

add a language to an installed ROS

http://xkcd.com/303/

-- you can generate graphviz of your dependencies


-- import redirector: put whatever.msg first in path, whatever/msg/__init__.py
   contains import hook code that also looks in $CMAKE_CURRENT_SOURCE_DIR/src/


-- there is python in 'src' dirs?  mixing conventions, those are for
   C++.  markup for which dir this is?

-- interface to binding generator scripts should be explicit in paths
otherwise these paths are calculated both in cmakeland and in pyland

-- buildsystem selftests (message generation, etc)  should be behind an option

-- rebuild all the message?  rm -rf $ROS_BUILD/gen/ and make 

-- silly to parse and gen separate times for each language build
   system should expose some python interface, do code generation once
   (?)  i.e. output a python file with a list of (classes?) to call
   per each .msg/.srv file

-- specify required versions of different packages?

-- weird recursive handling/duplication of CMAKE_TOOLCHAIN_FILE stuff



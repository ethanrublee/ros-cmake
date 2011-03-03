#!/usr/bin/env python

# Copyright (c) 2009, Willow Garage, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Willow Garage, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived from
#       this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

import sys, pickle, re, os, fileinput
from pprint import pprint
from pyPEG import parse, keyword, _and, _not
import pyPEG
pyPEG.print_trace = False

def quotedstring():
    return '"', -1, [re.compile('[^\\"]'), re.compile('\\.')], '"'

def arglist():
    return '(', -1, [quotedstring, re.compile(r'[^\s\(\)]+')], ')'

def macrocall():
    return re.compile(r'[^\s\(\)]+'), '(', -1, [comment, 
                                                quotedstring,
                                                re.compile(r'[^\s\(\)]+')], ')'
def cmake():
    return -2, [comment, macrocall]

def comment():
    return re.compile(r'#.*')

def reconstitute(thing):
    if isinstance(thing, tuple):
        if thing[0] == 'quotedstring':
            return '"' + ''.join(thing[1]) + '"'
        if thing[0] == 'comment':
            return thing[1] + '\n'
        assert False
    elif isinstance(thing, unicode) or isinstance(thing, str):
        return thing
    print "Uh oh, don't know how to reconstitute", thing, type(thing)
    assert False

def sanitize_one(inlists, pkgname):
    finput = fileinput.FileInput([inlists])
    ast = parse(cmake(), finput, True)

    oslist = ''
    oslist += 'if(EXISTS ${CMAKE_CURRENT_BINARY_DIR}/package.cmake)\n  include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)\nendif()\n'

    for line in ast:
        if line[0] == 'macrocall':
            if line[1][0].lower() in ['cmake_minimum_required',
                                      'rosbuild_init',
                                      'rosbuild_genmsg',
                                      'rosbuild_gensrv',
                                      'rosbuild_find_ros_package',
                                      'genaction',
                                      'gencfg',
                                      'install',
                                      'rosbuild_check_for_sse']:
                continue

            if line[1][0].lower() == 'set':
                if line[1][1] in ['ROS_BUILD_TYPE', 
                                  'EXECUTABLE_OUTPUT_PATH',
                                  'LIBRARY_OUTPUT_PATH',
                                  'CMAKE_BUILD_TYPE',
                                  'CMAKE_INSTALL_RPATH',
                                  'CMAKE_INSTALL_RPATH_USE_LINK_PATH',
                                  'CMAKE_BUILD_WITH_INSTALL_RPATH',
                                  'CMAKE_SKIP_BUILD_RPATH',
                                  'WXSWIG_EXECUTABLE']:
                    continue
            # strip leading 'bin/' from executables
            if line[1][0] in ['rosbuild_add_executable', 'target_link_libraries', 'rosbuild_link_boost']:
                while line[1][1].startswith('bin/'):
                    line[1][1] = line[1][1][4:]

            if line[1][0] ==  'rosbuild_add_library':
                while line[1][1].startswith('lib/'):
                    line[1][1] = line[1][1][4:]

            if line[1][0] == 'include':
                if line[1][1] == '$ENV{ROS_ROOT}/core/rosbuild/rosbuild.cmake':
                    continue
                if line[1][1] == '$ENV{ROS_ROOT}/core/rosbuild/rosconfig.cmake':
                    continue
                if line[1][1] == '${dynamic_reconfigure_PACKAGE_PATH}/cmake/cfgbuild.cmake':
                    continue
                if line[1][1] == '$ENV{ROS_ROOT}/core/rosbuild/FindPkgConfig.cmake':
                    continue
                if line[1][1] == '${actionlib_PACKAGE_PATH}/cmake/actionbuild.cmake':
                    line[1][1] = '${actionlib_msgs_PACKAGE_PATH}/cmake/actionbuild.cmake'

                if line[1][1] == '$ENV{ROS_ROOT}/core/rosbuild/FindPkgConfig.cmake':
                    continue


            #print line
            oslist += '%s(%s)\n' % (line[1][0], ' '.join([reconstitute(x) 
                                                          for x in
                                                          line[1][1:]]))
        if line[0] == 'comment':
            oslist += line[1] + '\n'

    return oslist

rosbuild_header = "if(ROSBUILD)\n  include(rosbuild.cmake)\n  return()\nendif()"

def add_rosbuild_header(fname):
    """
    add rosbuild prefix
    """
    txt = open(fname).read()
    if not txt.startswith(rosbuild_header):
        ofile = open(fname, 'w')
        print >>ofile, rosbuild_header
        print >>ofile, txt,
        ofile.close()

def sanitize(index):
    for k, v in index.iteritems():
        if k == ('__langs', None):
            continue

        if not os.path.isfile(v['srcdir'] + '/CMakeLists.txt'):
            f = open(v['srcdir'] + '/CMakeLists.txt', 'w')
            print >>f, "# autogenerated dummy file"
            f.close()
        os.chdir(v['srcdir'])

        otxt = sanitize_one(v['srcdir'] + '/CMakeLists.txt', k[0])
        oslistfilename = v['srcdir'] + '/rosbuild.cmake'
        if not os.path.isfile(oslistfilename):
            oslistfile = open(oslistfilename, 'w')
            print >>oslistfile, otxt
        add_rosbuild_header(v['srcdir'] + '/CMakeLists.txt')


from optparse import OptionParser
parser = OptionParser("options")
parser.add_option('-f', '--file', dest='file',
                  help='sanitize individual file')
parser.add_option('-i', '--index', dest='index',
                  help='sanitize all files in this index')

(options, args) = parser.parse_args(sys.argv)

if options.index:
    print "Sanitizing cmakelists from index", options.index
    index = pickle.load(open(options.index))
    sanitize(index)
    print
elif options.file:
    print "Sanitizing individual cmakelists", 
    print sanitize_one(options.file, "UNK")

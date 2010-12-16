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
# pyPEG.print_trace = True

def identifier(): 
    return 

def arglist():
    return '(', -1, re.compile(r'[^\s\(\)]+'), ')'

def macrocall():
    return re.compile(r'[^\s\(\)]+'), '(', -1, re.compile(r'[^\s\(\)]+'), ')'

def cmake():
    return -2, [comment, macrocall]

def comment():
    return re.compile(r'#.*')

def sanitize(index):
    for k, v in index.iteritems():
        if k == ('__langs', None):
            continue
        # print v['srcdir']
        if not os.path.isfile(v['srcdir'] + '/CMakeLists.txt'):
            continue
        os.chdir(v['srcdir'])
        os.popen('svn revert CMakeLists.txt').read()
        inlists = v['srcdir'] + '/CMakeLists.txt'
        # print inlists
        itext = open(inlists).read()
        # print '\n\n\n', itext, '\n\n\n' 
        finput = fileinput.FileInput([inlists])
        ast = parse(cmake(), finput, True)
        # pprint(ast)

        oslist = open(v['srcdir'] + '/CMakeLists.txt', 'w')
        
        print >>oslist, 'message("%s ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}")' % k[0]
        print >>oslist, ("include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)")

        for line in ast:
            if line[0] == 'macrocall':
                if line[1][0] in ['cmake_minimum_required',
                                  'rosbuild_init',
                                  'rosbuild_genmsg',
                                  'rosbuild_gensrv']:
                    continue

                if line[1][0] in ['set', 'Set', 'SET']:
                    if line[1][1] in ['ROS_BUILD_TYPE', 
                                      'EXECUTABLE_OUTPUT_PATH',
                                      'LIBRARY_OUTPUT_PATH',
                                      'CMAKE_BUILD_TYPE',
                                      'CMAKE_INSTALL_RPATH',
                                      'CMAKE_INSTALL_RPATH_USE_LINK_PATH',
                                      'CMAKE_BUILD_WITH_INSTALL_RPATH',
                                      'CMAKE_SKIP_BUILD_RPATH']:
                        continue
                if line[1][0] == 'include':
                    if line[1][1] == '$ENV{ROS_ROOT}/core/rosbuild/rosbuild.cmake':
                        continue
                    if line[1][1] == '$ENV{ROS_ROOT}/core/rosbuild/rosconfig.cmake':
                        continue
                print >>oslist, "%s(%s)" % (line[1][0], ' '.join(line[1][1:]))
            if line[0] == 'comment':
                print >>oslist, line[1]

        oslist.close()
        print k[0],
        sys.stdout.flush()

print "Sanitizing cmakelists from index", sys.argv[1] 
index = pickle.load(open(sys.argv[1]))
sanitize(index)
print

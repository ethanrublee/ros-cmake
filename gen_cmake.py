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

from __future__ import with_statement

import os, re, sys, string, glob, subprocess, time
import distutils.version
from optparse import OptionParser
import threading
import traceback
import math
import signal
import exceptions
from pprint import pprint

import roslib
import roslib.rospack
import roslib.rosenv
import roslib.stacks

from rosbuild import Package

parser = OptionParser("Generate various files for cmake's consumption"
                      "to avoid having to script all this in cmakeish")
parser.add_option('--ros_build', dest='ros_build', 
                  help='ROS_BUILD aka CMAKE_BINARY_DIR')
parser.add_option('--outfile', dest='outfile',   
                  help='file relative to ROS_BUILD to contain all the generated codes.')
parser.add_option('--verbose', dest='verbose',
                  help='haikus are easy / but sometimes they dont make sense / refrigerator')

(options, args) = parser.parse_args()


pkg_names = roslib.packages.list_pkgs()

packages = {}
# -I
# ${prefix}
# -L
# -l
# -Wl,-rpath,
# `something`

def expand_cmdline(s, d):
    s = re.sub(r'\$\{prefix\}', d, s)
    def shexpand(matchobj):
        # split into args
        argv = matchobj.group()[1:-1].split(' ')  
        # run it, get result
        # print "SUBPROC: ", argv
        res = subprocess.Popen(argv, stdout=subprocess.PIPE).communicate()[0]
        return res.rstrip()
    return re.sub(r'\`[^\`]*\`', shexpand, s)
    
for package_name in pkg_names:
    m = roslib.manifest.load_manifest(package_name)
    cf = ' '.join(m.get_export('cpp', 'cflags'))
    lf = ' '.join(m.get_export('cpp', 'lflags'))
    pfx = roslib.packages.get_pkg_dir(package_name)
    p = Package()
    p.prefix = pfx
    p.stack = roslib.stacks.stack_of(package_name)
    p.deps = set(roslib.rospack.rospack_depends(package_name))
    # print "$$$", p.deps
    p.cf = expand_cmdline(cf, pfx)
    p.lf = expand_cmdline(lf, pfx)
    p.include_dirs = []
    p.lib_dirs = []
    p.rpaths = []
    p.libs = []
    p.relpath = ''
    p.bindir = ''

    pattern = r'(-I|-L|-Wl,-rpath,|-l)\s*([^\s]+)'

    flagmap = { u'-I' : 'include_dirs', 
                u'-L': 'lib_dirs',
                u'-Wl,-rpath,': 'rpaths',
                u'-l': 'libs' 
                }

    def handle(t, value, p=p):
        a = getattr(p, flagmap[t])
        a += [value]

    for m in re.finditer(pattern, p.cf):
        handle(*m.groups())
    for m in re.finditer(pattern, p.lf):
        handle(*m.groups())

    packages[package_name] = p

# pprint(packages)

#
#  Write toplevel 'generated.cmake'
#
generated_cmake = os.path.join(options.ros_build, options.outfile)
print "Generating ", generated_cmake
generated = open(generated_cmake, 'w')

langs = roslib.rospack.rospackexec(['langs']).split()
print "rospack found langs '%s'" % ' '.join(langs)
print >>generated, 'set(ROSBUILD_LANGS %s CACHE STRING "List of enabled languages")' % ' '.join(langs)
print >>generated, 'message(STATUS "Enabled lanaguages (ROSBUILD_LANGS) ${ROSBUILD_LANGS}")'
print >>generated, "set(ROSBUILD_GEN_TARGETS ", \
    ' '.join(["%s_msggen %s_srvgen" % (x,x) for x in langs]), ')'

print >>generated, 'macro(_rosbuild_genmsg_impl)'
for j in langs:
    print >>generated, 'genmsg_%s()' % j[3:]
print >>generated, 'endmacro(_rosbuild_genmsg_impl)'

print >>generated, 'macro(_rosbuild_gensrv_impl)'
for j in langs:
    print >>generated, 'gensrv_%s()' % j[3:]
print >>generated, 'endmacro(_rosbuild_gensrv_impl)'

for j in langs:
    r = roslib.rospack.rospackexec(['export', '--lang=roslang', '--attrib=cmake', j])
    # print "####", r
    print >>generated, 'message(STATUS Reading %s)' % r 
    print >>generated, 'include(%s)' % r 

# 
#  Package-tree hoopla
#
cmd = """if(EXISTS %s/CMakeLists.txt)
  add_subdirectory(%s %s)
endif()"""

print >>generated, 'message(STATUS "Reading packages in dependency order")'

def write_project_cmake(packages, name):

    pkg = packages[name]

    fh = open(pkg.bindir + '/project.cmake', 'w')
    

    def maybe(fh, macro, value):
        if len(value) > 0:
            print >>fh, "%s(%s)" % (macro, ' '.join(value))

    print >>fh, "#" * 72, "\n# package %s\n" % name, "#" * 72

    print >>fh, 'message(STATUS "> %s")' % name
    print >>fh, "project(%s)" % name
    print >>fh, "set(ROSBUILD_PACKAGE_RELATIVE_PATH %s)" % pkg.bindir

    print >>fh, r'set(STACK_NAME "%s")' % pkg.stack

    print >>fh, r'add_custom_target(%s_codegen)' % name

    if len(pkg.deps):
        print >>fh, "add_dependencies(%s_codegen %s)" % \
            (name, ' '.join([x + "_codegen" for x in pkg.deps]))

    for dependee_name in pkg.deps:
        dependee = packages[dependee_name]
        print >>fh, "#\n# exported by %s\n#" % dependee_name
        
        maybe(fh, 'include_directories', dependee.include_dirs)
        maybe(fh, 'link_directories', dependee.lib_dirs)
        maybe(fh, 'link_libraries', dependee.libs)
    fh.close()

def dumpdeps(packages, written):
    
    leaves = []
    for k,v in packages.iteritems():
        if len(v.deps.difference(written)) == 0 and k not in written:
            leaves += [k]

    for l in leaves:
        pkg = packages[l]
        # print l, "<::", ' '.join(list(pkg.deps))

        srcdir = pkg.prefix
        stack = pkg.stack

        if stack:
            stackdir = roslib.stacks.get_stack_dir(stack)
            # print "stackdir:", stackdir
            relpath = os.path.relpath(srcdir, stackdir)
            pkg.relpath = relpath
            bindir = os.path.join(stack, relpath)
            pkg.bindir = bindir
        else:
            # print "BING BING BING", l, pkg.bindir
            pkg.stack = 'NOTFOUND'
            pkg.relpath = l # use package name
            pkg.bindir = l

        try:
            os.makedirs(bindir)
        except OSError, e:
            pass

        write_project_cmake(packages, l)

        print >>generated, cmd % (srcdir, srcdir, bindir)
        
        written.add(l)
        # print l,
        
        # m = roslib.manifest.load_manifest(l)
        # cflags = m.get_export('cpp', 'cflags')
        # lflags = m.get_export('cpp', 'lflags')
        # print cflags, lflags

# pprint(pkgdeps)

written = set([])
pdsize = 0
totalsize = len(packages)
while pdsize < totalsize:
    dumpdeps(packages, written)
    if len(packages) == pdsize:
        raise RuntimeError, "Uh oh, we didn't manage to write anything out...  circular dependency?"
    pdsize = len(written)
print "Done generating", options.outfile
print >>generated, 'message(STATUS "Done reading packages.")'

generated.close()

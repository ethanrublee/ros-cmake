#! /usr/bin/env python

# Copyright (c) 2010, Willow Garage, Inc.
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


# Author Troy Straszheim/straszheim@willowgarage.com

import os
import re
import distutils.version
import sys, string
import subprocess
import time
import getopt
import threading
import traceback
import math
import signal
import exceptions
from pprint import pprint

sys.path += [sys.argv[1]]

import roslib
import roslib.rospack
import roslib.rosenv
import roslib.stacks

pkg_names = roslib.packages.list_pkgs()
#print pkg_names

pkgs = dict([(p, {}) for p in pkg_names])

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
    
for pkg in pkg_names:
    m = roslib.manifest.load_manifest(pkg)
    cf = ' '.join(m.get_export('cpp', 'cflags'))
    lf = ' '.join(m.get_export('cpp', 'lflags'))
    pfx = roslib.packages.get_pkg_dir(pkg)
    # print expand_cmdline(cf, pfx)
    d = {}
    d['prefix'] = pfx
    d['stack'] = roslib.stacks.stack_of(pkg)
    d['deps'] = roslib.rospack.rospack_depends(pkg)
    d['cf'] = expand_cmdline(cf, pfx)
    d['lf'] = expand_cmdline(lf, pfx)
    d['include_dirs'] = []
    d['lib_dirs'] = []
    d['rpaths'] = []
    d['libs'] = []


    pattern = r'(-I|-L|-Wl,-rpath,|-l)\s*([^\s]+)'

    flagmap = { u'-I' : 'include_dirs', 
                u'-L': 'lib_dirs',
                u'-Wl,-rpath,': 'rpaths',
                u'-l': 'libs' 
                }
    def handle(t, value, d=d):
        d[flagmap[t]] += [value]

    for m in re.finditer(pattern, d['cf']):
        handle(*m.groups())
    for m in re.finditer(pattern, d['lf']):
        handle(*m.groups())

    pkgs[pkg] = d

#print "+========== pkgs ========-=+"
#pprint(pkgs)
            
pkgdeps = dict([(pkg, set(roslib.rospack.rospack_depends(pkg)))
                for pkg in pkg_names])

# pprint(pkgdeps)

ROS_BUILD = sys.argv[2]

print "Writing package dependency tree in cmake-readable format to", ROS_BUILD
olists = open(ROS_BUILD, 'w')

cmd = """if(EXISTS %s/CMakeLists.txt)
  add_subdirectory(%s %s)
endif()"""

print >>olists, 'message(STATUS "Reading packages in dependency order")'

def write_deps(cmfile, pkg):
    #
    # for each l that we depend on
    # 
    for l in pkgs[pkg]['deps']:
        print >>cmfile, "#\n# exported by ", l, "\n#"
        print >>cmfile, "include_directories(%s)" % (' '.join(pkgs[l]['include_dirs']))
        print >>cmfile, "link_libraries(%s)" % (' '.join(pkgs[l]['libs']))
        print >>cmfile, "link_directories(%s)" % (' '.join(pkgs[l]['lib_dirs']))

def dumpdeps(d):
    
    leaves = []
    for k,v in d.iteritems():
        if len(v) == 0:
            leaves += [k]
    
    for l in leaves:
        srcdir = pkgs[l]['prefix']
        bindir = roslib.stacks.stack_of(l) + '/' + l

        try:
            os.makedirs(bindir)
        except OSError, e:
            pass
        localdefs = open(bindir + '/project.cmake', 'w')
        write_deps(localdefs, l)
        localdefs.close()
        print >>olists, cmd % (srcdir, srcdir, 
                               bindir)
        
        for k,v in d.iteritems():
            v.discard(l)
        del d[l]
        # print l,
        
        m = roslib.manifest.load_manifest(l)
        cflags = m.get_export('cpp', 'cflags')
        lflags = m.get_export('cpp', 'lflags')
        # print cflags, lflags


while len(pkgdeps) > 0:
    dumpdeps(pkgdeps)
                                                      
print "\nDone generating %s." % sys.argv[2]


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


# Author Tully Foote/tfoote@willowgarage.com

from __future__ import with_statement

import os, re, sys, string, glob, subprocess, time
import threading
import traceback
import math
import signal
import exceptions
from pprint import pprint
import pickle

# -I
# ${prefix}
# -L
# -l
# -Wl,-rpath,
# `something`

def handle_rosboost(argv, i):
    d = dict()
    i['tools']['boost'] = d
    if argv[0] == '--lflags':
        d['COMPONENTS'] = argv[1].split(',')
    return ''

def expand_cmdline(s, d, i):
    s = re.sub(r'\$\{prefix\}', d, s)
    def shexpand(matchobj):
        # split into args
        argv = matchobj.group()[1:-1].split(' ')  
        # run it, get result
        print "SUBPROC: ", argv
        if argv[0] == 'rosboost-cfg':
            if 'tools' not in i:
                i['tools'] = {}
            return handle_rosboost(argv[1:], i)
        else:
            res = subprocess.Popen(argv, stdout=subprocess.PIPE).communicate()[0]
            return res.rstrip()
    return re.sub(r'\`[^\`]*\`', shexpand, s)
    
def sanitize(index):
    for k,v in index.iteritems():
        print k, v

        cf = ''
        lf = ''
        if 'export' in v:
            if 'cpp' in v['export']:
                if 'cflags' in v['export']['cpp']:
                    cf = v['export']['cpp']['cflags']
                    cf = expand_cmdline(cf, v['srcdir'], v)
                if 'lflags' in v['export']['cpp']:
                    lf = v['export']['cpp']['lflags']
                    lf = expand_cmdline(lf, v['srcdir'], v)

        v['include_dirs'] = []
        v['lib_dirs'] = []
        v['libs'] = []
        v['rpaths'] = []

        pattern = r'(-D|-I|-L|-Wl,-rpath,|-l)\s*([^\s]+)'
    
        flagmap = { u'-I' : 'include_dirs', 
                    u'-L' : 'lib_dirs',
                    u'-Wl,-rpath,' : 'rpaths',
                    u'-l' : 'libs', 
                    u'-D' : 'defines' 
                    }
    
        def handle(t, value, v=v):
            key = flagmap[t]
            #a = t[flagmap[t]]
            if key not in v:
                v[key] = []
            v[key] += [value]
            # print ">>>>>>>>>>", t, value
    
        for m in re.finditer(pattern, cf):
            handle(*m.groups())
        for m in re.finditer(pattern, lf):
            handle(*m.groups())
    


ifile = open(sys.argv[1])
index = pickle.load(ifile)
sanitize(index)
pprint(index)

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
pyPEG.print_trace = True

def envvar():
    return 'ENV{', [dereference, re.compile(r'[\w\d_]+')], '}'

def dereference():
    return '$', [envvar, ('{', re.compile(r'[\w\d_]+'), '}')]

def identifier(): 
    return [dereference, re.compile(r'[^\s\(\)]+')]

def macrocall():
    return identifier, '(', -1, identifier, ')'

def cmake():
    return -2, macrocall

def comment():
    return re.compile(r'#.*')

def sanitize(index):
    for k, v in index.iteritems():
        print v['srcdir']
        if not os.path.isfile(v['srcdir'] + '/CMakeLists.txt'):
            continue
        inlists = v['srcdir'] + '/CMakeLists.txt'
        oslist = open(v['srcdir'] + '/CMakeLists.txt.fixed', 'w')
        
        print inlists
        #groups = re.findall(r'([^\(]+)\s*\(([^\)]*)\)\s*', inlists, re.MULTILINE)
        #print groups[0]
        #print groups[1]
        #print
        finput = fileinput.FileInput([inlists])
        ast = parse(cmake(), finput, True, comment)
        pprint(ast)

        #call = groups[0]
        #args = groups[1].split()
        #print call, args

        oslist.close()
        sys.exit(0)

index = pickle.load(open(sys.argv[1]))
sanitize(index)



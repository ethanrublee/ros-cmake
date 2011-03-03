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
import yaml

from pprint import pprint
from pyPEG import parse, keyword, _and, _not
import pyPEG
pyPEG.print_trace = False

def generate(index):
    index.pop(('__langs', None))
    for k, v in index.iteritems():

        def mv(key):
            if key in v and len(v[key]) > 0:
                data[key] = v[key]
        data = {}

        na = 'not available'
        mv('url')
        mv('author')
        mv('brief')
        mv('license')
        mv('msgs')
        mv('srvs')
        mv('cfgs')
        mv('actions')
        mv('depend')
        mv('pythondirs')

        data['description'] = v.get('description', na)
        if data['description'] == None:
            data['description'] = na
        data['description'] = data['description'].replace('\n', ' ')

        e = v.get('export', {})
        e.pop('lib_dirs', None)
        e.pop('cpp', None)

        if len(e) > 0:
            data['export'] = e

        if len(v['3rdparty']) > 0:
            data['3rdparty'] = list(v.get('3rdparty'))

        f = open(v['srcdir'] + '/rosbuild.manifest', 'w')
        print >>f, "#\n# rosbuild.manifest for %s\n#" % k[0]
        yaml.dump(data, f, default_flow_style=False)
        f.close()


from optparse import OptionParser
parser = OptionParser("options")

parser.add_option('-i', '--index', dest='index',
                  help='sanitize all files in this index')

(options, args) = parser.parse_args(sys.argv)

if options.index:
    print "generate_manifest from index", options.index
    index = pickle.load(open(options.index))
    generate(index)

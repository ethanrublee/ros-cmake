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

import os, re, sys, glob, subprocess
import exceptions
from pprint import pprint
import pickle, pyPEG
pyPEG.print_trace = True

import manifest_parse

# -I
# ${prefix}
# -L
# -l
# -Wl,-rpath,
# `something`

def parse(s):
    ast = []
    print "parsing: >>>%s<<<" % s
    if len(s) == 0:
        return ast
    ast, remaining = pyPEG.parseLine(s, manifest_parse._start(), ast, False)
    assert remaining == '', "oops remaining is %s" % remaining
    return ast


def expand_cmdline(s, d, i):
    # kill extraneous includes
    s = re.sub(r'-I\$\{prefix\}/msg/cpp', '', s)
    s = re.sub(r'-I\$\{prefix\}/srv/cpp', '', s)
    # expand prefix
    s = re.sub(r'\$\{prefix\}', d, s)
    def shexpand(matchobj):
        # split into args
        argv = matchobj.group()[1:-1].split(' ')  
        # run it, get result
        # print "SUBPROC: ", argv
        res = subprocess.Popen(argv, stdout=subprocess.PIPE).communicate()[0]
        return res.rstrip()
    return re.sub(r'\`[^\`]*\`', shexpand, s)
    
def backtick_eval(ast, ctx, d):
    print "backtick_eval:", ast
    if isinstance(ast, tuple):
        if ast[0] == 'boost':
            if 'tools' not in d:
                d['tools'] = {}
            if 'boost' not in d['tools']:
                d['tools']['boost'] = dict()
            if len(ast[1]) > 0:
                d['tools']['boost']['COMPONENTS'] = ast[1]
        else:
            assert False, "unknown backtick: " +str(ast)
    else:
        assert False, "backtick not a tuple:" +str(ast)

def evaluate(ast, ctx, d):
    print "evaluate:", ast, "ctx:", ctx

    if isinstance(ast, str):
        return ast

    if isinstance(ast, list):
        s = ""
        for i in ast:
            s += evaluate(i, ctx, d)
        return s

    if isinstance(ast, tuple):
        assert len(ast) == 2
        if ast[0] == 'dollar_brace_var':
            s = evaluate(ast[1], ctx, d)
            if s not in ctx:
                return s + "_NOTFOUND"
            return ctx[s]

        if 'export' not in d:
            d['export'] = {}
        def handle(ast, ctx, d, dest):
            if dest not in d['export']:
                d['export'][dest] = []
            d['export'][dest] += [evaluate(ast, ctx, d)]
            return ''

        if ast[0] == 'lib_dir':
            handle(ast[1], ctx, d, 'lib_dirs')
            return ''

        if ast[0] == 'define':
            handle(ast[1], ctx, d, 'defines')
            return ''

        if ast[0] == 'link_lib':
            handle(ast[1], ctx, d, 'libs')
            return ''

        if ast[0] == 'includeflag':
            if ast[1] == [(u'dollar_brace_var', ['prefix']), '/msg/cpp']:
                return ''
            if ast[1] == [(u'dollar_brace_var', ['prefix']), '/srv/cpp']:
                return ''

            handle(ast[1], ctx, d, 'include_dirs')
            return ''

        if ast[0] == 'rpath':
            return ''

        if ast[0] == 'backtick':
            backtick_eval(ast[1][0], ctx, d)
            return ''
        assert False, "meh " + ast[0] 
        # return '[' + ast[0] + ' skipped]'


def sanitize(index):

    for k,v in index.iteritems():
        #print '$$$', k, v

        if 'export' in v:
            context = dict(prefix=v['srcdir'],
                           CMAKE_BINARY_DIR='${CMAKE_BINARY_DIR}')
            
            print k[0], '\r',
            sys.stdout.flush()
            exp = v['export']
            if 'cpp' in v['export']:
                if 'cflags' in v['export']['cpp']:
                    cf = v['export']['cpp']['cflags']
                    evaluate(parse(cf), context, v)
                    #print cf, parse(cf)
                    #cf = expand_cmdline(cf, v['srcdir'], v)
                if 'lflags' in v['export']['cpp']:
                    lf = v['export']['cpp']['lflags']
                    evaluate(parse(lf), context, v)
                    #print lf, parse(lf)
                    #lf = expand_cmdline(lf, v['srcdir'], v)
            if 'roslang' in v['export']:
                cmake = v['export']['roslang']['cmake']
                index[('__langs',None)][k[0]] = expand_cmdline(cmake, v['srcdir'], v)
            if 'swig' in v['export']:
                swigflags = v['export']['swig']['flags']
                print "swigflags=", swigflags
                ast = parse(swigflags)
                print ast


def get_recursive_depends(index, pkgname):
    v = index[(pkgname, None)]
    # print v
    rdep = set([])
    if 'depend' not in v:
        return rdep
    for dep in v['depend']:
        # print ">>>", dep
        rdep.add(dep)
        rdep.update(get_recursive_depends(index, dep))
    return rdep


ifile = open(sys.argv[1])
index = pickle.load(ifile)
ifile.close()

index[('__langs', None)] = {}

print "Sanitizing manifest index..."
sanitize(index)

print "Generating full recursive dependencies"
for (k, _) in index:
    if k == '__langs':
        continue
    print "r: %50s\r" % k, ; sys.stdout.flush()
    rdep = get_recursive_depends(index, k)
    index[(k, None)]['recursive_depends'] = rdep
    

ofile = open(sys.argv[1], 'w')
pickle.dump(index, ofile)
ofile.close()
print 


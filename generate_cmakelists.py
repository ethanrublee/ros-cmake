#!/usr/bin/env python

import os, os.path, sys, pprint, pickle

print "\nIndex@ sys.argv[1]:\n"


ifile = open(sys.argv[1])
index = pickle.load(ifile)

out = open(sys.argv[2] +'/toplevel.cmake', 'w')

def msg(format, *args):
    global out
    print >>out, ("message(STATUS \"" + format + "\")") % args

def subdir(srcdir, bindir):
    global out
    print >>out, "if(EXISTS %s/CMakeLists.txt)\n  add_subdirectory(%s %s)\nendif()" \
        % (srcdir, srcdir, bindir)

langs = []
for k,v in index[('__langs', None)].iteritems():
    msg("... %s", k)
    print >>out, 'include(%s)' % v
    langs += [k]

print >>out, 'set(ROSBUILD_LANGS\n  %s\n  CACHE STRING "List of enabled languages")' % ' '.join(langs)
msg("Enabled lanaguages (ROSBUILD_LANGS) = ${ROSBUILD_LANGS}")
print >>out, "set(ROSBUILD_GEN_TARGETS\n  ", \
    ' '.join(["%s_msggen %s_srvgen" % (x,x) for x in langs]), ')'

print >>out, 'macro(_rosbuild_genmsg_impl)'
for j in langs:
    print >>out, '  genmsg_%s()' % j[3:]
print >>out, 'endmacro(_rosbuild_genmsg_impl)'

print >>out, 'macro(_rosbuild_gensrv_impl)'
for j in langs:
    print >>out, '  gensrv_%s()' % j[3:]
print >>out, 'endmacro(_rosbuild_gensrv_impl)'



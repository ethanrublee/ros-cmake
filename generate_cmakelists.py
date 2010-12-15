#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob

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

print >>out, 'macro(rosbuild_msgs)'
for j in langs:
    print >>out, '  genmsg_%s(${ARGV})' % j[3:]
print >>out, 'endmacro()'

print >>out, 'macro(rosbuild_srvs)'
for j in langs:
    print >>out, '  gensrv_%s(${ARGV})' % j[3:]
print >>out, 'endmacro()'

del index[('__langs', None)]

print >>out, '#\n#\n#'

for (pkgname, version), d in index.iteritems():
    print >>out, "set(%s_PACKAGE_PATH %s)" % (pkgname, d['srcdir'])

def write_project_cmake(name, d):
    print ">>>", name
    bindir = sys.argv[2] + '/' + name
    os.mkdir(bindir)
    ofile = open(bindir + '/package.cmake', 'w')
    print >>ofile, 'project(%s)' % name
    print >>ofile, 'message(STATUS "^^-- %s")' % name
    print >>ofile, 'rosbuild_msgs(%s)' % ' '.join(d['msgs'])
    print >>ofile, 'rosbuild_srvs(%s)' % ' '.join(d['srvs'])
    subdir(d['srcdir'], name)

def dump(index, written = set([])):

    for (pkgname, version), d in index.iteritems():
        print pkgname

    leaves = []
    for k, v in d['depend']:
        if len(written.difference(set(v))) == 0 and k not in written:
            leaves += [k]
    
    for l in leaves:
        print ">>>", l


def build_depgraph(index, depgraph = {}):
    for (pkg, version), d in index.iteritems():
        if 'depend' in d:
            depgraph[pkg] = set(d['depend'])
        else:
            depgraph[pkg] = set([])
    return depgraph

depgraph = build_depgraph(index)
written = set([])

notfound = set([])
unsatisfied = set([])
for pkg, deps in depgraph.iteritems():
    for dep in deps:
        if dep not in depgraph:
            notfound.add(dep)
            unsatisfied.add(pkg)


if len(notfound) > 0:
    print "The following packages have unsatisfied dependencies:"
    print ">>> ", ' '.join(unsatisfied)
    print "The missing packages are:"
    print ">>> ", ' '.join(notfound)
    sys.exit(0)

while len(depgraph) > 0:
    for pkg, deps in depgraph.iteritems():
        deps.difference_update(written)

        if len(deps) == 0 and pkg not in written:
            write_project_cmake(pkg, index[(pkg, None)])
            written.add(pkg)
    for pkg in written:
        if pkg in depgraph:
            del depgraph[pkg]

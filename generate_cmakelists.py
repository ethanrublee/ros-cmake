#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob, em

print "\nIndex@ sys.argv[1]:\n"


ifile = open(sys.argv[1])
index = pickle.load(ifile)

out = open(sys.argv[2] +'/toplevel.cmake', 'w')

package_em = open(sys.argv[3] + '/package.cmake.em').read()

src_pythonpath = []
for (pkgname, version), d in index.iteritems():
    if pkgname != '__langs':
        print >>out, "set(%s_PACKAGE_PATH %s)" % (pkgname, d['srcdir'])
    if 'pythondirs' in d:
        src_pythonpath += d['pythondirs']

print >>out, "include(${CMAKE_CURRENT_BINARY_DIR}/toplevel.static.cmake)"

print >>out, "set(ROSBUILD_PYTHONPATH " + ':'.join(src_pythonpath) + ")"
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

#print >>out, "set(ROSBUILD_GEN_TARGETS\n  ", \
#    ' '.join(["%s_msggen %s_srvgen" % (x,x) for x in langs]), ')'

print >>out, 'macro(rosbuild_msgs)'
for j in langs:
    print >>out, '  genmsg_%s(${ARGV})' % j[3:]
print >>out, 'endmacro()'

print >>out, 'macro(rosbuild_srvs)'
for j in langs:
    print >>out, '  gensrv_%s(${ARGV})' % j[3:]
print >>out, 'endmacro()'

print >>out, 'macro(rosbuild_gentargets)'
for j in langs:
    print >>out, '  gentargets_%s(${ARGV})' % j[3:]
print >>out, 'endmacro()'

# for j in langs:
#     print >>out, 'add_custom_target(%s_codegen)' % j

del index[('__langs', None)]

print >>out, '#\n#\n#'

def write_project_cmake(name, d, index=index):
    print ">>>", name, '                    \r',
    sys.stdout.flush()
    bindir = sys.argv[2] + '/' + name
    if not os.path.isdir(bindir):
        os.mkdir(bindir)
    ofile = open(bindir + '/package.cmake', 'w')

    pkgdict = dict(PROJECT = name)

    print >>ofile, 'include(${CMAKE_CURRENT_BINARY_DIR}/pkg.cmake)'

    pkgdict['DEPENDED_PACKAGE_PATHS'] = [index[(pkgname, None)]['srcdir']
                                         for pkgname in d['depend']]

    pkgdict['GENERATED_ACTIONS'] = d['actions']

    pkgdict['msgs'] = d['msgs']
    pkgdict['srvs'] = d['srvs']

    pkgdict['exported_include_dirs'] = []

    if 'export' in d:
        if 'include_dirs' in d['export']:
            pkgdict['exported_include_dirs'] = d['export']['include_dirs']

    libs_i_need = []
    defines = []
    assert 'recursive_depends' in d
    for pkgname in d['recursive_depends']:
        pkg = index[(pkgname, None)]
        if 'export' in pkg:
            if 'include_dirs' in pkg['export']:
                print >>ofile, 'include_directories(%s)' % \
                    ' '.join(pkg['export']['include_dirs'])
            if 'libs' in pkg['export']:
                libs_i_need += pkg['export']['libs']
            if 'lib_dirs' in pkg['export']:
                print >>ofile, 'link_directories(%s)' % ' '.join(pkg['export']['lib_dirs'])
            if 'defines' in pkg['export']:
                defines += pkg['export']['defines']

    pkgdict['recursive_depends'] = d['recursive_depends']

    if len(d['recursive_depends']) > 0:
        print >>ofile, "add_dependencies(%s_gen_cpp "%name + ' '.join(["%s_gen_cpp" % x for x in d['recursive_depends']]) + ")"

    pkgdict['libs_i_need'] = libs_i_need
    pkgdict['defines'] = ['-D'+x for x in defines]

    subdir(d['srcdir'], name)
    pysrcdir = os.path.join(d['srcdir'], 'src')
    
    if 'pythondirs' in d:
        for pdir in d['pythondirs']:
            print >>ofile, 'install(DIRECTORY %s DESTINATION python COMPONENT %s PATTERN ".svn" EXCLUDE REGEX ".*\\\.py$")' \
            % (pdir, name)

#    print >>ofile, 'install(DIRECTORY %s DESTINATION share COMPONENT %s PATTERN ".svn" EXCLUDE REGEX ".*\\.(launch|xml|yaml|dox|srv|msg|cmake")' \
    #% (d['srcdir'], name)

    em_ofile = open(bindir + '/pkg.cmake', 'w')
    print >>em_ofile, em.expand(package_em, pkgdict)
    
    
def dump(index, written = set([])):

    for (pkgname, version), d in index.iteritems():
        print pkgname

    leaves = []
    for k, v in d['depend']:
        if len(written.difference(set(v))) == 0 and k not in written:
            leaves += [k]

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

print

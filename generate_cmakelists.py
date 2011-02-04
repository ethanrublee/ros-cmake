#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob, em

print "\nIndex@ sys.argv[1]:\n"


ifile = open(sys.argv[1])
index = pickle.load(ifile)

langs = index.pop(('__langs', None))
print "LANGS=", langs

package_em = open(sys.argv[3] + '/package.cmake.em').read()

src_pythonpath = []

for (pkgname, version), d in index.iteritems():
    if 'pythondirs' in d:
        src_pythonpath += d['pythondirs']

topo_pkgs = []

def write_project_cmake(name, d, index=index):
    global topo_pkgs
    print ">>>", name, '                    \r',
    sys.stdout.flush()
    bindir = sys.argv[2] + '/' + name
    if not os.path.isdir(bindir):
        os.mkdir(bindir)
    pkgdict = dict(PROJECT = name)

    pkgdict['brief_doc'] = d.get('brief', "no brief description")
    pkgdict['description'] = d.get('description', "no description")

    pkgdict['DEPENDED_PACKAGE_PATHS'] = [index[(pkgname, None)]['srcdir']
                                         for pkgname in d['depend']]

    pkgdict['GENERATED_ACTIONS'] = d['actions']

    pkgdict['msgs'] = d['msgs']
    pkgdict['srvs'] = d['srvs']
    pkgdict['cfgs'] = d['cfgs']
    pkgdict['thirdparty'] = d['3rdparty'] if '3rdparty' in d else []

    pkgdict['exported_include_dirs'] = []

    if 'export' in d:
        if 'include_dirs' in d['export']:
            pkgdict['exported_include_dirs'] = d['export']['include_dirs']

    libs_i_need = pkgdict['libs_i_need'] = []
    includes_i_need = pkgdict['includes_i_need'] = []
    link_dirs = pkgdict['link_dirs'] = []
    swig_flags = pkgdict['swig_flags'] = []
    defines = []

    assert 'recursive_depends' in d
    for pkgname in d['recursive_depends']:
        pkg = index[(pkgname, None)]
        pkgcomment = [r'# %s' % pkgname]
        if 'export' in pkg:
            if 'include_dirs' in pkg['export']:
                includes_i_need += pkg['export']['include_dirs']

            if 'libs' in pkg['export']:
                libs_i_need += pkgcomment + pkg['export']['libs']

            if 'defines' in pkg['export']:
                defines += pkg['export']['defines']

            if 'swig' in pkg['export']:
                pkgdict['swig_flags'] += pkgcomment + pkg['export']['swig']['flags']
                
    pkgdict['recursive_depends'] = d['recursive_depends']

    pkgdict['defines'] = ['-D'+x for x in defines]

    topo_pkgs += [name]

    pkgdict['pythondirs'] = d.get('pythondirs', [])

#    print >>ofile, 'install(DIRECTORY %s DESTINATION share COMPONENT %s PATTERN ".svn" EXCLUDE REGEX ".*\\.(launch|xml|yaml|dox|srv|msg|cmake")' \
    #% (d['srcdir'], name)

    ofile = open(bindir + '/package.cmake', 'w')
    print >>ofile, em.expand(package_em, pkgdict)
    
    
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


toplevel_em = open(sys.argv[3] + '/toplevel.cmake.em').read()
toplevel_out = open(sys.argv[2] + '/toplevel.cmake', 'w')
toplevel_out.write(em.expand(toplevel_em, dict(packages=index,
                                               langs=langs,
                                               src_pythonpath=src_pythonpath,
                                               topo_pkgs=topo_pkgs)))


cpack_em = open(sys.argv[3] + '/make_debs.sh.em').read()
cpack_out = open(sys.argv[2] + '/make_debs.sh', 'w')
cpack_out.write(em.expand(cpack_em, dict(projects = topo_pkgs)))

                                         

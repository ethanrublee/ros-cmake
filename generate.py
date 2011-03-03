#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob, em, yaml, rosbuild2

print "\nGenerating cmakelists in", sys.argv[1]

MANIFEST="rosbuild.manifest"

if len(sys.argv) == 1:
    print "usage: %s <ros_package_path>"
    sys.exit(1)

def get_package_dirs(p):
    pkgs = []
    def visit(arg, dirname, names):
        if MANIFEST in names:
            names[:] = [] # stop recursion
            if dirname not in rosbuild2.thirdparty_projects + rosbuild2.broken_projects:
                arg += [dirname]
            else:
                print "Skipping", dirname

    os.path.walk(p, visit, pkgs)
    return pkgs
    
pkgpath = sys.argv[1].split(':')

pkgdirs = []
for path in pkgpath:
    pkgdirs += get_package_dirs(path)

#print pkgdirs

index = {}
for pkgdir in pkgdirs:
    d = yaml.load(open(pkgdir + "/" + MANIFEST))
    d['srcdir'] = pkgdir
    index[os.path.basename(pkgdir)] = d
    
# generate 'recursive' dependencies 
def get_recursive_depends(index, pkgname, stack=[]):
    if pkgname not in index:
        raise Exception("Uh oh, can't find %s in index to calculate dependencies.  stack=%s" % (pkgname, stack))
    v = index[pkgname]
    # print v
    rdep = set([])
    if 'depend' not in v:
        return rdep
    for dep in v['depend']:
        # print ">>>", dep
        rdep.add(dep)
        rdep.update(get_recursive_depends(index, dep, stack + [pkgname]))
    return rdep

for k in index:
    rdep = get_recursive_depends(index, k)
    index[k]['recursive_depends'] = rdep
    
langs = {}

for k, v in index.iteritems():
    if 'export' in v and 'roslang' in v['export']:
        langs[k] = v['export']['roslang']['cmake']

#pprint.pprint(index)
#print "langs=", langs
# sys.exit(0)

# langs = index.pop(('__langs', None))
# print "LANGS=", langs

package_em = open(sys.argv[2] + '/package.cmake.em').read()
config_em = open(sys.argv[2] + '/package-config.cmake.em').read()
pkgconfig_em = open(sys.argv[2] + '/pkgconfig.pc.em').read()

src_pythonpath = []

for pkgname, d in index.iteritems():
    if 'pythondirs' in d:
        src_pythonpath += d['pythondirs']

topo_pkgs = []

def write_project_cmake(name, d, index=index):
    global topo_pkgs
    print ">>>", name, '                    \r',
    sys.stdout.flush()
    bindir = sys.argv[3] + '/' + name
    if not os.path.isdir(bindir):
        os.mkdir(bindir)
    pkgdict = dict(PROJECT = name)

    pkgdict['brief_doc'] = d.get('brief', "no brief description")
    pkgdict['description'] = d.get('description', "no description")

    if 'depend' in d:
        pkgdict['DEPENDED_PACKAGE_PATHS'] = [index[pkgname]['srcdir']
                                             for pkgname in d['depend']]
    else:
        pkgdict['DEPENDED_PACKAGE_PATHS'] = []

    pkgdict['GENERATED_ACTIONS'] = d.get('actions', [])
    
    pkgdict['msgs'] = d.get('msgs', [])
    pkgdict['srvs'] = d.get('srvs', [])
    pkgdict['cfgs'] = d.get('cfgs', [])
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

    pkgdict['config_libraries'] = d.get('export', {}).get('libs', [])
    pkgdict['config_definitions'] = d.get('export', {}).get('defines', [])

    pkgdict['depend'] = d.get('depend', [])
    assert 'recursive_depends' in d
    for pkgname in d['recursive_depends']:
        pkg = index[pkgname]
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
    
    oconfig_file = open(bindir + '/' + name + '-config.cmake.in', 'w')
    print >>oconfig_file, em.expand(config_em, pkgdict)
    
    pkgconfig_file = open(bindir + '/' + name + '.pc.in', 'w')
    print >>pkgconfig_file, em.expand(pkgconfig_em, pkgdict)
    
    
def build_depgraph(index, depgraph = {}):
    for pkg, d in index.iteritems():
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
            write_project_cmake(pkg, index[pkg])
            written.add(pkg)
    
    for pkg in written:
        if pkg in depgraph:
            del depgraph[pkg]

print


toplevel_em = open(sys.argv[2] + '/toplevel.cmake.em').read()
toplevel_out = open(sys.argv[3] + '/toplevel.cmake', 'w')

d = dict(packages=index,
         langs=langs,
         src_pythonpath=src_pythonpath,
         topo_pkgs=topo_pkgs)

print "Writing toplevel...."
toplevel_out.write(em.expand(toplevel_em, d))


cpack_em = open(sys.argv[2] + '/make_debs.sh.em').read()
cpack_out = open(sys.argv[3] + '/make_debs.sh', 'w')
cpack_out.write(em.expand(cpack_em, dict(projects = topo_pkgs)))

                                         

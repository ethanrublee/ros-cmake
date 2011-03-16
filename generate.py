#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob, em, yaml, rosbuild2, pprint
from StringIO import StringIO
from xml.etree import *
import xml.etree.ElementTree

print "\nGenerating cmakelists in", sys.argv[1]

MANIFEST="manifest.xml"

if len(sys.argv) == 1:
    print "usage: %s <ros_package_path>"
    sys.exit(1)

def get_package_dirs(p):
    pkgs = []
    def visit(arg, dirname, names):
        if MANIFEST in names:
            names[:] = [] # stop recursion
            arg += [dirname]

    os.path.walk(p, visit, pkgs)
    return pkgs
    
pkgpath = sys.argv[1].split(':')

pkgdirs = []
for path in pkgpath:
    pkgdirs += get_package_dirs(path)

#print pkgdirs

index = {}
for pkgdir in pkgdirs:
    print ">>", pkgdir
    txt = open(pkgdir + "/" + MANIFEST).read()
    d = xml.etree.ElementTree.fromstring(txt)
    rb2 = d.find('rosbuild2')
    if rb2:
        rb2.set('srcdir', pkgdir)
        bn = os.path.basename(pkgdir)
        index[bn] = rb2
        #print bn, "RB2=", rb2

# generate 'recursive' dependencies 
def get_recursive_depends(index, pkgname, stack=[]):
    if pkgname not in index:
        raise Exception("Uh oh, can't find %s in index to calculate dependencies.  stack=%s" % (pkgname, stack))
    v = index[pkgname]
    # print pkgname
    rdep = set([])
    for dep in v.findall('depend'):
        if 'package' not in dep.attrib:
            continue
        else:
            # print pkgname, ">>>", dep
            _ = dep.attrib['package']
            #print ">!>!", _
            rdep.add(_)
            rdep.update(get_recursive_depends(index, _, stack + [pkgname]))

    #print pkgname, "rdep=", rdep
    return rdep

for k in index:
    rdep = get_recursive_depends(index, k)
    # print "rd=", rdep
    index[k].attrib['recursive_depends'] = rdep
    #print "ttr:", k, index[k].attrib['recursive_depends']
langs = {}

for k, v in index.iteritems():
    #print "VEEE:", v
    for l in v.findall('export/roslang'):
        #print "WOO:", l.attrib
        langs[k] = l.attrib['cmake']

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
    # print ">>>", name, '                    \r',
    sys.stdout.flush()
    bindir = sys.argv[3] + '/' + name
    if not os.path.isdir(bindir):
        os.mkdir(bindir)
    pkgdict = dict(PROJECT = name)

    pkgdict['brief_doc'] = d.get('brief', "no brief description")
    pkgdict['description'] = d.get('description', "no description")

    pkgdict['DEPENDED_PACKAGE_PATHS'] = [index[pkgname].attrib['srcdir']
                                         for pkgname in 
                                         [x.attrib['package'] 
                                          for x in d.findall('depend') 
                                          if 'package' in x.attrib]]

    pkgdict['GENERATED_ACTIONS'] = d.get('actions', [])
    
    msgs = d.find('msgs')
    pkgdict['msgs'] = msgs.text if msgs != None else ''
    srvs = d.find('srvs')
    pkgdict['srvs'] = srvs.text if srvs != None else ''
    pkgdict['cfgs'] = d.get('cfgs', [])
    pkgdict['thirdparty'] = [x.attrib['thirdparty']
                             for x in d.findall('depend')
                             if 'thirdparty' in x.attrib]
    pkgdict['srcdir'] = d.attrib['srcdir']

    pkgdict['exported_include_dirs'] = [x.text for x in 
                                        d.findall('export/include_dir')]

    libs_i_need = pkgdict['libs_i_need'] = []
    includes_i_need = pkgdict['includes_i_need'] = []
    link_dirs = pkgdict['link_dirs'] = []
    swig_flags = pkgdict['swig_flags'] = []
    defines = []

    pkgdict['config_libraries'] = d.get('export', {}).get('libs', [])
    pkgdict['config_definitions'] = d.get('export', {}).get('defines', [])

    pkgdict['depend'] = [x.attrib['package'] for x in d.findall('depend') 
                         if 'package' in x.attrib]

    assert 'recursive_depends' in d.attrib
    # print "RECDEPS:", name, "->", d.attrib['recursive_depends']
    for pkgname in d.attrib['recursive_depends']:
        #print "CHECKDEP", pkgname
        pkg = index[pkgname]
        pkgcomment = r'  # %s' % pkgname
        for l in pkg.findall('export/lib'):
            libs_i_need += [l.text + pkgcomment]

        for i in pkg.findall('export/include_dir'):
            includes_i_need += [i.text + "  # " + pkgname]

        for d in pkg.findall('export/define'):
            defines += [d.text + "  # " + pkgname]

            
        if 'export' in pkg:
            #if 'include_dirs' in pkg['export']:
            #    includes_i_need += pkg['export']['include_dirs']

            if 'defines' in pkg['export']:
                defines += pkg['export']['defines']

            if 'swig' in pkg['export']:
                pkgdict['swig_flags'] += pkgcomment + pkg['export']['swig']['flags']
                
    pkgdict['recursive_depends'] = d.attrib['recursive_depends']

    pkgdict['defines'] = ['-D'+x for x in defines]

    topo_pkgs += [name]

    pkgdict['pythondirs'] = d.get('pythondirs', [])

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
# pprint.pprint(d)

toplevel_out.write(em.expand(toplevel_em, d))


cpack_em = open(sys.argv[2] + '/make_debs.sh.em').read()
cpack_out = open(sys.argv[3] + '/make_debs.sh', 'w')
cpack_out.write(em.expand(cpack_em, dict(projects = topo_pkgs)))

                                         

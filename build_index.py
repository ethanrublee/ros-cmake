#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob
from rosbuild2 import *

dot = open('dependencies.dot', 'w')

print "\nBuilding index of packages in", sys.argv[2]

if len(sys.argv) == 1:
    print "usage: %s indexfile_name ros_package_path"
    sys.exit(1)

def get_package_dirs(p):
    pkgs = []
    def visit(arg, dirname, names):
        if 'manifest.xml' in names:
            names[:] = [] # stop recursion
            arg += [dirname]

    os.path.walk(p, visit, pkgs)
    return pkgs
    
pkgpath = sys.argv[2].split(':')

pkgdirs = []
for path in pkgpath:
    pkgdirs += get_package_dirs(path)

# print pkgdirs

import lxml.objectify

def get_idlspecs(idltype, srcdir):
    idls = glob.glob(srcdir + '/' + idltype + '/*.' + idltype)
    short_idlspecs = [x[len(srcdir)+1:] for x in idls]
    return short_idlspecs

def load_manifest(path, main_index):
    manifest_path = path + '/manifest.xml'
    f = open(manifest_path)
    s = f.read()
    obj = lxml.objectify.fromstring(s)
    # print lxml.objectify.dump(obj)
    pkgname = os.path.basename(path)

    if pkgname in thirdparty_projects + broken_projects + ['cmake']:
        return

    print ">>> %30s\r" % pkgname, ; sys.stdout.flush()
    sys.stdout.flush()
    version = None

    key = (pkgname, version)
    
    entry = {}
    entry['srcdir'] = path
    main_index[key] = entry
    
    pyinits = glob.glob(path + '/src/*/__init__.py')
    if len(pyinits) > 0:
        entry['pythondirs'] = map(lambda d: os.path.dirname(os.path.dirname(d)), 
                                  pyinits)

    entry['msgs'] = get_idlspecs('msg', path)
    entry['srvs'] = get_idlspecs('srv', path)
    entry['actions'] = get_idlspecs('action', path)
    entry['cfgs'] = get_idlspecs('cfg', path)
    entry['3rdparty'] = set([])

    for x in 'author', 'license', 'url':
        if x in obj.__dict__:
            entry[x] = obj.__dict__[x].text
    if 'description' in obj.__dict__:
        entry['description'] = obj.description.text
        if 'brief' in obj.description.attrib:
            entry['brief'] = obj.description.attrib['brief']

    if 'depend' in obj.__dict__:
        # print ">>>", [x.attrib for x in obj.depend]
        entry['depend'] = [x.attrib['package'] for x in obj.depend 
                           if x.attrib['package'] != 'rosbuild']
    else:
        entry['depend'] = []

    if 'export' in obj.__dict__:
        export = {}
        entry['export'] = export
        for x in ['cpp', 'python', 'roslang', 'rosdep', 'swig', 'rosbuild']:
            if x in obj.export.__dict__:
                export[x] = {}
                for attr in obj.export.__dict__[x].attrib:
                    export[x][attr] = obj.export.__dict__[x].attrib[attr]

main_index = {}

for pkg in pkgdirs:
    load_manifest(pkg, main_index)


# pprint.pprint(main_index)

ofile = open(sys.argv[1], 'w')

pickle.dump(main_index, ofile)

print

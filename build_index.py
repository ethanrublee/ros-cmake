#!/usr/bin/env python

import os, os.path, sys, pprint, pickle, glob

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

def get_msgs(srcdir):
    msgs = glob.glob(srcdir + "/msg/*.msg")
    short_msgs = [x[len(srcdir)+1:] for x in msgs]
    return short_msgs

def get_srvs(srcdir):
    srvs = glob.glob(srcdir + "/srv/*.srv")
    short_srvs = [x[len(srcdir)+1:] for x in srvs]
    return short_srvs

def load_manifest(path, main_index):
    manifest_path = path + '/manifest.xml'
    f = open(manifest_path)
    s = f.read()
    obj = lxml.objectify.fromstring(s)
    # print lxml.objectify.dump(obj)
    pkgname = os.path.basename(path)
    print pkgname,
    sys.stdout.flush()
    version = None

    key = (pkgname, version)
    
    entry = {}
    entry['srcdir'] = path
    main_index[key] = entry
    
    msgs = get_msgs(path)
    entry['msgs'] = msgs

    srvs = get_srvs(path)
    entry['srvs'] = srvs

    for x in 'author', 'license', 'url':
        if x in obj.__dict__:
            entry[x] = obj.__dict__[x].text
    if 'description' in obj.__dict__:
        entry['description'] = obj.description.text
        if 'brief' in obj.description.attrib:
            entry['brief'] = obj.description.attrib['brief']

    if 'depend' in obj.__dict__:
        # print ">>>", [x.attrib for x in obj.depend]
        entry['depend'] = [x.attrib['package'] for x in obj.depend if x.attrib['package'] != 'rosbuild']

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

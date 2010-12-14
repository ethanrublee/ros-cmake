#!/usr/bin/env python

import os, os.path, sys, pprint, pickle

print "\nIndex@ sys.argv[1]:\n"


ifile = open(sys.argv[1])
index = pickle.load(ifile)

ofile = open(sys.argv[2] +'/toplevel.cmake', 'w')

for k,v in index[('__langs', None)].iteritems():
    print >>ofile, 'message(STATUS "... %s")' % k
    print >>ofile, 'include(%s)' % v


#!/usr/bin/env python

import os, os.path, sys, pprint, pickle

print "\nIndex@ sys.argv[1]:\n"


ifile = open(sys.argv[1])

index = pickle.load(ifile)

pprint.pprint(index)


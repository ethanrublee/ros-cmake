#!/usr/bin/env python

s = "-I/foo/bar -I${prefix}/blang -llibbiness -L/other/dir -D`uname` -Wl,-rpath,somerpath"

l = list(s)
l.reverse()


def ipath(l):
    i = 0
    r = ''
    while l[i] != ' ':
        r += l[i]
    print "IPATH:", r
    return

def lpath(l):
    i = 0
    r = ''
    while l[i] != ' ':
        r += l[i]
    print "IPATH:", r
    return


def parse(l):
    s = {}

    def next(l):
        n = l.pop()
        return n

    def path(l):
        n = next(l)
        r = ''
        while n not in [' ', '`', '$', '{', '}']:
            r += n
            n = next(l)
        l.append(n)
        print "PATH", r

    def identifier(l):
        n = next(l)
        while n != '}':
            

    def compflag(l):
        n = next(l)
        if n == 'L':
            print "libflag"
            path(l)
        elif n == 'I':
            print "incflag"
            path(l)

    def subshell(l):
        n = next(l)
        r = ''
        while n != '`':
            r += n
            n = next(l)
        print "subshell: ", r

    while True:
        n = next(l)
        if n == ' ':
            pass
        elif n == '-':
            compflag(l)
        elif n == '`':
            subshell(l)
        elif n == '$':
            identifier(l)
        else:
            print "??", n

parse(l)

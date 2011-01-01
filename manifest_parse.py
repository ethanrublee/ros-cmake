#!/usr/bin/env python

from pprint import pprint
import pyPEG, re
pyPEG.print_trace = False

STAR = -1
PLUS = -2
def REPEAT(x): 
    return x
# tuples are sequence
# lists are alternatives

def _ws():
    return pyPEG.ignore(r'\s+')

def identifier():
    return re.compile(r'\w+')

def _bare():
    return re.compile(r'[\w\-/\+=]+')

def dollar_brace_var():
    return '${', re.compile(r'\w+'), '}'

def _path():
    return PLUS, [dollar_brace_var, backtick, _bare]

def backtick():
    return r'`', re.compile(r'(\\`|[^`])+'), r'`'

def flagarg():
    return PLUS, [_path(), backtick]

def includeflag():
    return '-I', PLUS, [_path(), backtick]

def link_dir():
    return '-L', flagarg()

def link_lib():
    return '-l', flagarg()

def define():
    return '-D', flagarg()

def rpath():
    return '-Wl,-rpath,', flagarg()

def arg():
    return [includeflag, link_dir, link_lib, define, rpath, _path]

def _start():
    return STAR, _ws(), arg(), STAR, (_ws(), arg()), STAR, _ws()


from nose.tools import eq_

def test_one():
    ast=[]
    ast, unparsed = pyPEG.parseLine(r'''-I${prefix}/bl-Iam/`back \`tiiick`boom    
-lfunk${prefix}schwing''', 
                                    _start, ast, False)
    print "unparsed=>>>%s<<<" % unparsed
    pprint(ast)


def check(txt, expect_unparsed, expect_ast = []):
    ast = []
    ast, unparsed = pyPEG.parseLine(txt, _start, ast, False)
    eq_(unparsed, expect_unparsed)
    eq_(ast, expect_ast)
    print "unparsed=", unparsed
    pprint(ast)

def test_gen():
    examples = [('-Llibdir -llibname -Iincdir barestring', '', [(u'link_dir', [(u'bare', 'libdir')]),
                                                                (u'link_lib', [(u'bare', 'libname')]),
                                                                (u'includeflag', [(u'bare', 'incdir')]),
                                                                (u'path', [(u'bare', 'barestring')])]),
                ('-I${prefix}/src', '', [(u'includeflag', 
                                          [(u'dollar_brace_var', ['prefix']), 
                                           (u'bare', '/src')])]),
                (' -Wl,-rpath,${prefix}/boom   ', '', [(u'rpath', 
                                                        [(u'dollar_brace_var', ['prefix']), 
                                                         (u'bare', '/boom')])])
                ]
    for e,u,a in examples:
        yield check, e, u, a

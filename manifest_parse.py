#!/usr/bin/env python

from pprint import pprint
import pyPEG, re, subprocess
pyPEG.print_trace = False
from pyPEG import ignore, keyword

STAR = -1
PLUS = -2
def REPEAT(x): 
    return x
# tuples are sequence
# lists are alternatives

def ws():
    return ignore(r'\s+')

def identifier():
    return re.compile(r'\w+')

def _bare():
    return re.compile(r'[\w\-/\+=,]+')

def dollar_brace_var():
    return '${', re.compile(r'\w+'), '}'

def _path():
    return PLUS, [dollar_brace_var, backtick, _bare]

def _cflags():
    return ignore('--cflags')

def boost():
    return 'rosboost-cfg', ws, [ignore('--cflags'), 
                                (ignore('--lflags'), ws, re.compile(r'\w+'), STAR, (',', re.compile(r'\w+')))]

def backtick():
    return r'`', PLUS, [dollar_brace_var, _bare, ws], r'`'

def flagarg():
    return PLUS, [_path(), backtick]

def includeflag():
    return '-I', PLUS, [_path(), backtick]

def lib_dir():
    return '-L', flagarg()

def link_lib():
    return '-l', flagarg()

def define():
    return '-D', flagarg()

def rpath():
    return '-Wl,-rpath,', flagarg()

def arg():
    return [includeflag, lib_dir, link_lib, define, rpath, _path]

def _start():
    return STAR, ws, arg(), STAR, (ws, arg()), STAR, ws

#
# traversal
#
def traverse(ast, ctx, callback, if_):
    # print "expand_dollar_vars", ast
    if isinstance(ast, str):
        return ast

    if isinstance(ast, pyPEG.Name):
        return ast

    if isinstance(ast, list):
        l = map(lambda a: traverse(a, ctx, callback, if_), ast)
        if if_(list):
            return callback(l)
        else:
            return l

    if isinstance(ast, tuple):
        assert len(ast) == 2

        if if_(ast[0]):
            result = callback(ast[1], ctx)
            return result
        return tuple(map(lambda a: traverse(a, ctx, callback, if_), ast))
 
    assert False, "shouldn't be here: type(ast)=%s" % str(type(ast))

def expand_dollar_vars(var, ctx = dict(prefix="FOO")):
    return ctx[var[0]]

def expand_backticks(var, ctx):
    assert isinstance(var, list)

    newargs = []
    for f in var:
        if isinstance(f, tuple):
            assert f[0] == 'ws'
        else:
            assert isinstance(f, str)
            newargs += [f]
    
    subproc = subprocess.Popen(newargs, stdout=subprocess.PIPE)
    res = subproc.communicate()[0]
    rs = res.rstrip()
    return [rs]

#
# testiness
# 
from nose.tools import eq_



def check(txt, expect_unparsed, expect_ast = []):
    print '\n\n\n'
    ast = []
    ast, unparsed = pyPEG.parseLine(txt, _start, ast, False)
    eq_(unparsed, expect_unparsed)
    eq_(ast, expect_ast)
    print "unparsed=", unparsed
    pprint(ast)

def test_gen():
    examples = [('-Llibdir -llibname -Iincdir barestring', '', [(u'lib_dir', ['libdir']),
                                                                (u'link_lib', ['libname']),
                                                                (u'includeflag', ['incdir']),
                                                                'barestring']),
                ('-I${prefix}/src', '', [(u'includeflag', 
                                          [(u'dollar_brace_var', ['prefix']), 
                                           '/src'])]),
                (' -Wl,-rpath,${prefix}/boom   ', '', [(u'rpath', 
                                                        [(u'dollar_brace_var', ['prefix']), 
                                                         '/boom'])]),
                ('`rosboost-cfg --cflags`', '', [(u'backtick', [(u'boost', [])])]),
                ('`rosboost-cfg --lflags thread,system`', '', [(u'backtick', [(u'boost', ['thread', 'system'])])]),
                ('-I${PREFIX}/sth -foo -bar -blam${prefix}blam -Dblah', '', 
                 [(u'includeflag', [(u'dollar_brace_var', ['PREFIX']), '/sth']), 
                  (u'ws', []), 
                  '-foo', 
                  (u'ws', []), 
                  '-bar', 
                  (u'ws', []), 
                  '-blam', 
                  (u'dollar_brace_var', ['prefix']), 'blam', 
                  (u'ws', []), 
                  (u'define', ['blah'])])
                ]
    for e,u,a in examples[-1:]:
        yield check, e, u, a


def test_expand():
    examples =[('-I${prefix}/sr`voom`c', 
                [(u'includeflag', ['FOO', '/sr', 'EXPvoomPXE', 'c'])], 
                dict(prefix='FOO')),
               ]

    for txt, expected, ctx in examples:
        # print txt, expected, ctx
        ast,unparsed = pyPEG.parseLine(txt, _start, [], False)
        result = traverse(ast, ctx, 'dollar_brace_var', expand_dollar_vars)
        result = traverse(result, ctx, 'backtick', expand_backticks)
        # print "result=", result
        eq_(result, expected)


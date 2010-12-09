import imp, sys, os

class MetaLoader(object):
    def __init__(self, f, pathname, desc, overwrite = False):
        self.f = f
        self.pathname = pathname
        self.desc = desc
        self.overwrite = overwrite

    def load_module(self, name):
        if self.overwrite or name not in sys.modules:
            # print "try load:", self.f, self.pathname, self.desc
            module = imp.load_module(name, self.f, self.pathname, self.desc)
            sys.modules[name] = module
            if '.' in name:
                parent_name, child_name = name.rsplit('.', 1)
                setattr(sys.modules[parent_name], child_name, module)
        else:
            pass
            # print name, "already in sys.modules" 

        return sys.modules[name]
        

class MetaImporter(object):

    def __init__(self, modname, staticpath, genpath):
        self.modname = modname
        self.genpath = genpath
        self.staticpath = staticpath
        # print "$$$$$", modname, genpath
        f, pathname, desc = imp.find_module(modname, [staticpath])
        # print "#####", f, pathname, desc
        loader = MetaLoader(f, pathname, desc, overwrite=True)
        loader.load_module(modname)

    def find_module(self, fullname, path=None):

        # print "fullname=%s path=%s modname=%s" % (fullname, path, self.modname)

        if not fullname or not fullname.startswith(self.modname):
            #print "*** not fullname"
            return

        if fullname == self.modname:
            # print "head=", head, "tail=", tail
            imppath = os.path.join(self.staticpath, *head.split('.'))
            # print "imppath", imppath
            f, pathname, desc = imp.find_module(tail, [imppath])
            return MetaLoader(f, pathname, desc)

        head, tail = fullname.rsplit('.', 1)
        # print "$$$", head, tail
        msgmod = self.modname + '.msg'
        if fullname == msgmod or fullname.startswith(msgmod + '.'):
            imppath = os.path.join(self.genpath, *head.split('.'))
            # print "%%%", tail, imppath
            f, pathname, desc = imp.find_module(tail, [imppath])
            return MetaLoader(f, pathname, desc)

        srvmod = self.modname + '.srv'
        if fullname == srvmod or fullname.startswith(srvmod + '.'):
            imppath = os.path.join(self.genpath, *head.split('.'))
            # print "---", tail, imppath
            f, pathname, desc = imp.find_module(tail, [imppath])
            return MetaLoader(f, pathname, desc)

        if fullname == self.modname or fullname.startswith(self.modname + '.'):

            # print "head=", head, "tail=", tail
            imppath = os.path.join(self.staticpath, *head.split('.'))
            # print "@@@", imppath
            f, pathname, desc = imp.find_module(tail, [imppath])
            return MetaLoader(f, pathname, desc)
        else:
            return

def add_hook(modulename, static_path, generated_path):
    """
    @param modulename name of module that contains both static and generated code
    @param static_path path to parent directory of module's static code
    @param generated_path path to parent directory of module's generated code

    so for a module 'foo'::
    
    add_hook('foo', '/path/to/static', '/path/to/gen')

    means that /path/to/static/foo exists and contains *static* python code,
    and /path/to/gen/foo/msg exists and contains *generated* python code.
    There are two prerequisites:  

    1.  /path/to/gen appears *first* in PYTHONPATH
    2.  /path/to/gen/__init__.py contains the above call to add_hook()
    """
    import sys
    hook = MetaImporter(modulename, static_path, generated_path)
    sys.meta_path.append(hook)

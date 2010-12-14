class Package:

    __slots__=['prefix',
               'stack',
               'deps',
               'cf',
               'lf',
               'include_dirs',
               'lib_dirs',
               'rpaths',
               'libs',
               'relpath',
               'bindir']


    def __repr__(self):
        s = "Package:\n"
        for key in self.__slots__:
            s += "\t" + key + ": " + repr(getattr(self, key)) + "\n"
        return s

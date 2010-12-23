#!/usr/bin/env python
# Software License Agreement (BSD License)
#
# Copyright (c) 2008, Willow Garage, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#  * Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#  * Neither the name of Willow Garage, Inc. nor the names of its
#    contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Revision $Id: gensrv_py.py 1030 2008-05-22 22:11:12Z sfkwc $

"""
ROS message source code generation for rospy.

Converts ROS .srv files into Python source code implementations.
"""
import sys, os, traceback, trace

import rosidl.srvs
import rosidl.packages

import genmsg_py, genutil

REQUEST ='Request'
RESPONSE='Response'

class SrvGenerationException(rosidl.genpy.MsgGenerationException): 
    pass

def srv_generator(package, name, spec):
    req, resp = ["%s%s"%(name, suff) for suff in [REQUEST, RESPONSE]]

    fulltype = '%s%s%s'%(package, rosidl.srvs.SEP, name)

    gendeps_dict = rosidl.gentools.get_dependencies(spec, package)
    md5 = rosidl.gentools.compute_md5(gendeps_dict)

    yield "class %s(rosidl.message.ServiceDefinition):"%name
    yield "  _type          = '%s'"%fulltype
    yield "  _md5sum = '%s'"%md5
    yield "  _request_class  = %s"%req
    yield "  _response_class = %s"%resp

class SrvGenerator(genutil.Generator):
    def __init__(self):
        super(SrvGenerator, self) \
            .__init__('gensrv_py', 'services', rosidl.srvs.EXT, 
                      'srv', SrvGenerationException)

    def generate(self, package, f, outdir):
        verbose = True
        f = os.path.abspath(f)
        infile_name = os.path.basename(f)
        if not os.path.exists(outdir):
            os.makedirs(outdir)
        elif not os.path.isdir(outdir): 
            raise SrvGenerationException("Cannot write to %s: file in the way"%outdir)

        prefix = infile_name[:-len(rosidl.srvs.EXT)]
        # generate message files for request/response        
        name, spec = rosidl.srvs.load_from_file(f, package)
        base_name = rosidl.names.resource_name_base(name)
        
        outfile = self.outfile_name(outdir, f)
        f = open(outfile, 'w')
        try:
            for mspec, suffix in ((spec.request, REQUEST), (spec.response, RESPONSE)):
                #outfile = os.path.join(outdir, prefix+suffix+".py")    
                #gen = rosidl.genpy.msg_generator(package, name+suffix, mspec)
                #self.write_gen(outfile, gen, rosidl.srvs.is_verbose())
                for l in rosidl.genpy.msg_generator(package, base_name+suffix, mspec):
                    f.write(l+'\n')

            # generate service file
            #outfile = os.path.join(outdir, prefix+".py")
            #self.write_gen(outfile, srv_generator(package, name, spec), verbose)
            for l in srv_generator(package, base_name, spec):
                f.write(l+'\n')
        finally:
            f.close()
        return outfile
    
if __name__ == "__main__":
    rosidl.srvs.set_verbose(True)
    tracer = trace.Trace(
        ignoredirs=[sys.prefix, sys.exec_prefix],
        trace=1)
    tracer.run("genutil.genmain(sys.argv, SrvGenerator())")


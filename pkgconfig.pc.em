prefix=@@CMAKE_INSTALL_PREFIX@@
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: @(brief_doc)
Description: @(description)
Version: unknown
Libs: -L${libdir} @(' '.join(['-l'+ lib for lib in config_libraries]))
Cflags: -I${includedir} @(' '.join(config_definitions))
Requires: @(' '.join(depend))

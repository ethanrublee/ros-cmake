project(eigen)

macro(rosbuild_3rdparty PKGNAME DEPFILE)

  configure_file(install.sh.in ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh
    @ONLY)
  # add_custom_target(3rdparty-${PKGNAME})

  #   add_custom_command(TARGET 3rdparty-${PKGNAME}
  #     PRE_BUILD
  #     COMMAND ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh
  #     COMMENT "Installing 3rd party ${PKGNAME}")

  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${DEPFILE}
    COMMAND ${CMAKE_CURRENT_BINARY_DIR}/3rdparty/install.sh
    COMMENT "Installing 3rdparty '${PKGNAME}'")

  add_custom_target(3rdparty-${PKGNAME}
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${DEPFILE})

  add_dependencies(3rdparty 3rdparty-${PKGNAME})

endmacro()



rosbuild_3rdparty(eigen include/Eigen/Eigen)


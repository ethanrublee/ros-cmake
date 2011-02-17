TODO List
=========

An assortment of loose ends.

* Many 3rdparty packages contain proper rosbuild executables in
  addition to the 3rdparty stuff, e.g. in ``prosilica_gige_sdk`` 's
  ``CMakeLists.txt`` you'll find::

    include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
    link_directories($ENV{PWD}/../lib)
    link_libraries(PvAPI)
    add_definitions(-D_LINUX -D_x86)
    set(EXAMPLES build/Prosilica_GigE_SDK/examples)
    rosbuild_add_executable(CLIpConfig ${EXAMPLES}/CLIpConfig/CLIpConfig.cpp)
    rosbuild_add_executable(Ping ${EXAMPLES}/Ping/Ping.cpp)
    rosbuild_add_executable(ListCameras ${EXAMPLES}/ListCameras/ListCameras.cpp)
    rosbuild_add_executable(ResetCamera ${EXAMPLES}/ResetCamera/ResetCamera.cpp)
    rosbuild_add_executable(ListAttributes ${EXAMPLES}/ListAttributes/ListAttributes.cpp)

  these need cleanup.






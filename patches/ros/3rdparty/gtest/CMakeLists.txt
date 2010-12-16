project(gtest)

rosbuild_3rdparty(gtest include/gtest/gtest.h)

find_library(GTEST_LIBRARIES
  gtest
  PATHS ${CMAKE_CURRENT_BINARY_DIR}/lib
  NO_DEFAULT_PATH)

  

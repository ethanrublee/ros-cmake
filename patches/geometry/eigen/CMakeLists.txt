project(eigen)

if(NOT EXISTS ${CMAKE_CURRENT_BINARY_DIR}/include/Eigen/Eigen)
  rosbuild_3rdparty(eigen include/Eigen/Eigen)
endif()

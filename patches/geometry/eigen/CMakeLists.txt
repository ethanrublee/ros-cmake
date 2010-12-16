project(eigen)

if(NOT EXISTS include/Eigen/Eigen)
  rosbuild_3rdparty(eigen include/Eigen/Eigen)
endif()

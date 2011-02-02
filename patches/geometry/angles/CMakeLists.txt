include(${CMAKE_CURRENT_BINARY_DIR}/package.cmake)
# Unit tests
rosbuild_add_gtest(utest test/utest.cpp)
target_link_libraries(utest ${CMAKE_THREAD_LIBS_INIT})


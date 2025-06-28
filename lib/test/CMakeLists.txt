enable_testing()

find_package(GTest REQUIRED)

file(GLOB test_src_files "*.cpp")
message(STATUS "Collected test source files: ${test_src_files}")
add_executable(utest_topk_minheap ${test_src_files})

target_link_libraries(utest_topk_minheap PRIVATE GTest::gtest GTest::gtest GTest::gtest_main)

add_test(NAME utest_topk_minheap COMMAND utest_topk_minheap)

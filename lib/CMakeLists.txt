cmake_minimum_required(VERSION 3.10)
project(minheap_topk_dpiclib)

set(CMAKE_CXX_STANDARD 17)

include_directories(${CMAKE_SOURCE_DIR}/include)

file(GLOB lib_dpic_src_files "src/*.cpp")

add_library(libtopk_minheap_dpic STATIC ${lib_dpic_src_files})

target_link_libraries(libtopk_minheap_dpic PRIVATE libtopk_minheap)

option(BUILD_TESTS "Build unit tests" ON)
if (BUILD_TESTS)
    enable_testing()
    add_subdirectory(test)
endif()

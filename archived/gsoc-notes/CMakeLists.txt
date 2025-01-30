cmake_minimum_required(VERSION 3.2)
project(boost-gsoc-quest)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_VERBOSE_MAKEFILE ON)

add_definitions(-DQ3_ENABLE_GENERAL_IMPL)

set(CMAKE_CXX_FLAGS_DEBUG "-g -DMALLOC_CHECK_=2")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

include_directories("/usr/include")
include_directories("/usr/local/include")
include_directories("/usr/include/c++/7.3.0") # Fix clion bug

include_directories(".")

#add_executable(quest1 boost-gsoc-quest-1.cc)
add_executable(quest2 boost-gsoc-quest-2.cc)
add_executable(quest3 boost-gsoc-quest-3.cc)

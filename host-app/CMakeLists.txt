cmake_minimum_required(VERSION 3.16)

project(host-app C CXX)

add_executable(host-app src/main.cpp)

include_directories(src/)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(host-app Threads::Threads)

set(TENSORFLOW_SOURCE_DIR "" CACHE PATH
  "Directory that contains the TensorFlow project" )
if(NOT TENSORFLOW_SOURCE_DIR)
  get_filename_component(TENSORFLOW_SOURCE_DIR
    "${CMAKE_CURRENT_LIST_DIR}/../../../../" ABSOLUTE)
endif()

add_subdirectory(
  "${TENSORFLOW_SOURCE_DIR}/tensorflow/lite"
  "${CMAKE_CURRENT_BINARY_DIR}/tensorflow-lite" EXCLUDE_FROM_ALL)

target_link_libraries(host-app tensorflow-lite)

add_executable(tf-app src/tflite.cpp)
target_link_libraries(tf-app tensorflow-lite)

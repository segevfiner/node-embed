cmake_minimum_required(VERSION 3.29)
project(node-embed)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(Node_ABI 115)
find_package(Node REQUIRED)

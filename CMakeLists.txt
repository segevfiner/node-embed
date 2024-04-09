cmake_minimum_required(VERSION 3.15...3.29)
project(node-embed)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)

set(Node_ABI_DEFAULT 115)
find_package(Node REQUIRED)

if(APPLE)
  set(CMAKE_INSTALL_RPATH "@executable_path/../lib")
elseif(UNIX)
  set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib")
endif()

add_executable(node-embed src/main.cpp)
target_link_libraries(node-embed PRIVATE Node::Node)

install(TARGETS node-embed RUNTIME_DEPENDENCY_SET node-embed)
install(RUNTIME_DEPENDENCY_SET node-embed)

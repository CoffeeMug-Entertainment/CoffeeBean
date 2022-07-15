cmake_minimum_required(VERSION 3.23.1)
project(CoffeeBean)

set(CMAKE_CXX_STANDARD 20)

set(CBE_SRC_DIR engine/src)

file(GLOB CBE_SRC ${CBE_SRC_DIR}/main.cpp)

add_definitions("-Wall -Wextra -pedantic")
add_executable(${PROJECT_NAME} ${CBE_SRC})

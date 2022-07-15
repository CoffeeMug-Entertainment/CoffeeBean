cmake_minimum_required(VERSION 3.23.1)
project(CoffeeBean)

set(CMAKE_CXX_STANDARD 20)

set(SDL_DIR engine/thirdparty/SDL2)
set(SDL_INC_DIR ${SDL_DIR}/include)
add_subdirectory(${SDL_DIR})

set(CBE_SRC_DIR engine/src)
file(GLOB CBE_SRC 
	${CBE_SRC_DIR}/App.cpp 
	${CBE_SRC_DIR}/main.cpp)

add_definitions("-Wall -Wextra -pedantic")
add_executable(${PROJECT_NAME} ${CBE_SRC})

target_include_directories(${PROJECT_NAME} PUBLIC ${SDL_INC_DIR})

target_link_libraries(${PROJECT_NAME} SDL2::SDL2)

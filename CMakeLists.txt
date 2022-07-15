cmake_minimum_required(VERSION 3.23.1)
project(CoffeeBean)

set(CMAKE_CXX_STANDARD 20)

# SDL2
set(SDL_DIR engine/thirdparty/SDL2)
set(SDL_INC_DIR ${SDL_DIR}/include)
add_subdirectory(${SDL_DIR})

# GLAD
set(GLAD_DIR engine/thirdparty/glad)
set(GLAD_INC_DIR ${GLAD_DIR}/include)
file(GLOB GLAD_SRC ${GLAD_DIR}/src/glad.c)
set(GLAD_LDFLAGS GL)

set(CBE_SRC_DIR engine/src)
file(GLOB CBE_SRC 
	${CBE_SRC_DIR}/App.cpp 
	${CBE_SRC_DIR}/main.cpp)

add_definitions("-Wall -Wextra -pedantic")
add_executable(${PROJECT_NAME} ${CBE_SRC} ${GLAD_SRC})

target_include_directories(${PROJECT_NAME} PUBLIC ${SDL_INC_DIR})
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC ${GLAD_INC_DIR})

IF(WIN32)
	#TODO(Fix): Yep
ELSEIF(UNIX)
	set(CBE_LDFLAGS SDL2::SDL2 ${GLAD_LDFLAGS} X11 pthread Xrandr Xi dl)
ENDIF()

target_link_libraries(${PROJECT_NAME} ${CBE_LDFLAGS})

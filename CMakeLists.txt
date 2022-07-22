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
IF(UNIX)
set(GLAD_LDFLAGS GL)
ENDIF()

# spdlog
set(SPDLOG_DIR engine/thirdparty/spdlog)
set(SPDLOG_INC_DIR ${SPDLOG_DIR}/include)
add_subdirectory(${SPDLOG_DIR})

# glm
set(GLM_DIR engine/thirdparty/glm)
set(GLM_INC_DIR ${GLM_DIR})
add_subdirectory(${GLM_DIR})

set(CBE_SRC_DIR engine/src)
file(GLOB CBE_SRC 
	${CBE_SRC_DIR}/App.cpp 
	${CBE_SRC_DIR}/Renderer/Shader.cpp
	${CBE_SRC_DIR}/Renderer/Buffers.cpp
	${CBE_SRC_DIR}/Renderer/Mesh.cpp
	${CBE_SRC_DIR}/Renderer/Model.cpp
	${CBE_SRC_DIR}/Renderer/Renderer.cpp
	${CBE_SRC_DIR}/Entities/Entity.cpp
	${CBE_SRC_DIR}/Entities/Components.cpp
	${CBE_SRC_DIR}/main.cpp)

IF(WIN32)
add_definitions("-Wall -pedantic")
ELSEIF(UNIX)
add_definitions("-Wall -Wextra -pedantic")
ENDIF()
add_executable(${PROJECT_NAME} ${CBE_SRC} ${GLAD_SRC})

target_include_directories(${PROJECT_NAME} PUBLIC ${CBE_SRC_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${SPDLOG_INC_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${SDL_INC_DIR})
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC ${GLAD_INC_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${GLM_INC_DIR})

IF(WIN32)
	set(CBE_LDFLAGS spdlog::spdlog SDL2::SDL2-static SDL2::SDL2main)
ELSEIF(UNIX)
	set(CBE_LDFLAGS spdlog::spdlog SDL2::SDL2 m pthread dl -static-libgcc -static-libstdc++)
ENDIF()

target_link_libraries(${PROJECT_NAME} ${CBE_LDFLAGS})

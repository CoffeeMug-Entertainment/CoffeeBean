cmake_minimum_required(VERSION 3.23.1)
project(CoffeeBean)

set(CMAKE_CXX_STANDARD 20)

# SDL2
set(SDL_DIR engine/thirdparty/SDL2)
set(SDL_INC_DIR ${SDL_DIR}/include)
set(BUILD_SHARED_LIBS OFF)
add_subdirectory(${SDL_DIR})

# GLAD
set(GLAD_DIR engine/thirdparty/glad)
set(GLAD_INC_DIR ${GLAD_DIR}/include)
file(GLOB GLAD_SRC ${GLAD_DIR}/src/glad.c)
IF(UNIX)
set(GLAD_LDFLAGS GL)
ENDIF()

# fmt
set(FMT_DIR engine/thirdparty/fmt)
set(FMT_INC_DIR ${FMT_DIR}/include)
add_subdirectory(${FMT_DIR})

# glm
set(GLM_DIR engine/thirdparty/glm)
set(GLM_INC_DIR ${GLM_DIR})
add_subdirectory(${GLM_DIR})

# stb
set(STB_DIR engine/thirdparty/stb)
set(STB_INC_DIR ${STB_DIR})

# EnTT
set(ENTT_DIR engine/thirdparty/EnTT)
add_subdirectory(${ENTT_DIR})

# simdjson
set(SIMDJSON_DIR engine/thirdparty/simdjson)
set(SIMDJSON_INC_DIR ${SIMDJSON_DIR})
file(GLOB SIMDJSON_SRC ${SIMDJSON_DIR}/simdjson.cpp)

set(CBE_SRC_DIR engine/src)
file(GLOB CBE_SRC 
	${CBE_SRC_DIR}/header_impl.cpp
	${CBE_SRC_DIR}/Importers/ObjImporter.cpp
	${CBE_SRC_DIR}/Renderer/Texture.cpp
	${CBE_SRC_DIR}/Renderer/Material.cpp
	${CBE_SRC_DIR}/Renderer/Shader.cpp
	${CBE_SRC_DIR}/Renderer/Buffers.cpp
	${CBE_SRC_DIR}/Renderer/Mesh.cpp
	${CBE_SRC_DIR}/Renderer/Model.cpp
	${CBE_SRC_DIR}/Renderer/Camera.cpp
	${CBE_SRC_DIR}/Renderer/Renderer.cpp
	${CBE_SRC_DIR}/Entities/Entity.cpp
	${CBE_SRC_DIR}/Entities/Components.cpp
	${CBE_SRC_DIR}/Input/Input.cpp
	${CBE_SRC_DIR}/App.cpp 
	${CBE_SRC_DIR}/main.cpp)

IF(WIN32)
add_definitions("-Wall -pedantic")
ELSEIF(UNIX)
add_definitions("-Wall -Wextra -pedantic")
ENDIF()
add_executable(${PROJECT_NAME} ${CBE_SRC} ${GLAD_SRC} ${SIMDJSON_SRC})

target_include_directories(${PROJECT_NAME} PUBLIC ${CBE_SRC_DIR})
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC ${FMT_INC_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${SDL_INC_DIR})
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC ${GLAD_INC_DIR})
target_include_directories(${PROJECT_NAME} SYSTEM PUBLIC ${GLM_INC_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${STB_INC_DIR})
target_include_directories(${PROJECT_NAME} PUBLIC ${SIMDJSON_INC_DIR})

IF(WIN32)
	set(CBE_LDFLAGS fmt::fmt SDL2::SDL2-static SDL2::SDL2main EnTT::EnTT)
ELSEIF(UNIX)
	set(CBE_LDFLAGS fmt::fmt SDL2::SDL2-static EnTT::EnTT m pthread dl -static-libgcc -static-libstdc++)
ENDIF()

target_link_libraries(${PROJECT_NAME} ${CBE_LDFLAGS})

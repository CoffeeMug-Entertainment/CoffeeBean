#ifndef CBE_MESH_H
#define CBE_MESH_H

#include "Buffers.h"

#include "glm/vec3.hpp"
#include "glm/vec4.hpp"

#include <vector>

namespace CBE
{
	struct Vertex
	{
		glm::vec3 position;
		glm::vec4 color;
	};

	struct Mesh
	{
		VAO vao;
		VBO vbo;
		EBO ebo;
		std::vector<Vertex> vertices;
		std::vector<unsigned int> indices;

		void Setup();
		void EmplaceVertex(glm::vec3 position = {0.0f, 0.0f, 0.0f}, glm::vec4 color = {1.0f, 1.0f, 1.0f, 1.0f});
	};
}

#endif

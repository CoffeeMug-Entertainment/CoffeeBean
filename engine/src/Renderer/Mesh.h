#ifndef CBE_MESH_H
#define CBE_MESH_H

#include "Buffers.h"

#include "glm/vec3.hpp"

#include <vector>

namespace CBE
{
	struct Vertex
	{
		glm::vec3 position;
	};

	struct Mesh
	{
		VAO vao;
		VBO vbo;
		EBO ebo;
		std::vector<Vertex> vertices;
		std::vector<unsigned int> indices;

		void Setup();
	};
}

#endif

#include "Mesh.h"
#include <fmt/core.h>

namespace CBE
{
	void Mesh::Setup()
	{
		vao.Generate();
		vao.Bind();

		vbo.Generate(&vertices[0], vertices.size() * sizeof(Vertex));
		ebo.Generate(&indices[0], indices.size() * sizeof(unsigned int));
		
		vao.LinkVBO(&vbo, 0);

		vao.Unbind();
		ebo.Unbind();
	}

	void Mesh::EmplaceVertex(glm::vec3 position, glm::vec3 normal, glm::vec2 texCoords, glm::vec4 color)
	{
		vertices.emplace_back(Vertex{position, normal, texCoords, color});
	}
}

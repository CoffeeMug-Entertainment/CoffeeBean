#include "Mesh.h"

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

	void Mesh::EmplaceVertex(glm::vec3 position, glm::vec4 color, glm::vec2 texCoords)
	{
		vertices.emplace_back(Vertex{position, color, texCoords});
	}
}

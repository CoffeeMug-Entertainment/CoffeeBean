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
}

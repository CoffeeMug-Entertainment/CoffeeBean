#include "Buffers.h"
#include "glad/glad.h"
#include "Mesh.h"

#include <cstddef>

namespace CBE
{
	void VBO::Generate(const GLvoid* vertices, GLsizeiptr size)
	{
		glGenBuffers(1, &id);
		glBindBuffer(GL_ARRAY_BUFFER, id);
		glBufferData(GL_ARRAY_BUFFER, size, vertices, GL_STATIC_DRAW);
	}

	void VBO::Delete()
	{
		glDeleteBuffers(1, &id);
	}

	void VBO::Bind()
	{
		glBindBuffer(GL_ARRAY_BUFFER, id);
	}

	void VBO::Unbind()
	{
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}

	void VAO::Generate()
	{
		glGenVertexArrays(1, &id);
	}

	void VAO::Delete()
	{
		glDeleteVertexArrays(1, &id);
	}

	void VAO::Bind()
	{
		glBindVertexArray(id);
	}

	void VAO::Unbind()
	{
		glBindVertexArray(0);
	}

	void VAO::LinkVBO(VBO* newVBO, GLuint layout)
	{
		vbo = newVBO;
		vbo->Bind();

		glVertexAttribPointer(layout, 3, GL_FLOAT, GL_FALSE,  sizeof(Vertex), (void*)0); //position
		glEnableVertexAttribArray(layout);

		glVertexAttribPointer(layout + 1, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, normal));
		glEnableVertexAttribArray(layout + 2);
		glVertexAttribPointer(layout + 2, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)offsetof(Vertex, texCoords));
		glEnableVertexAttribArray(layout + 2);
		glVertexAttribPointer(layout + 3, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (void*)(offsetof(Vertex, color)));
		glEnableVertexAttribArray(layout + 3);

		vbo->Unbind();
	}

	void EBO::Generate(const GLvoid* indices, GLsizeiptr size)
	{
		glGenBuffers(1, &id);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, size, indices, GL_STATIC_DRAW);
	}

	void EBO::Delete()
	{
		glDeleteBuffers(1, &id);
	}

	void EBO::Bind()
	{
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
	}

	void EBO::Unbind()
	{
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
}

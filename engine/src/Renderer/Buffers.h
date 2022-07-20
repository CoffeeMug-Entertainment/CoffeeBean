#ifndef CBE_GL_BUFFERS_H
#define CBE_GL_BUFFERS_H

#include "glad/glad.h"

namespace CBE
{
	struct VBO
	{
		GLuint id;

		void Generate(GLfloat* vertices, GLsizeiptr size);
		void Delete();
		void Bind();
		void Unbind();
	};

	struct VAO
	{
		GLuint id;
		VBO* vbo;

		void Generate();
		void Delete();
		void Bind();
		void Unbind();
		void LinkVBO(VBO* newVBO, GLuint layout);

	};

	struct EBO
	{
		GLuint id;

		void Generate(GLuint* indices, GLsizeiptr size);
		void Delete();
		void Bind();
		void Unbind();
	};
}

#endif

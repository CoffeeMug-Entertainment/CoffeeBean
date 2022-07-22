#ifndef CBE_SHADER_H
#define CBE_SHADER_H

#include "glad/glad.h"

#include <unordered_map>
#include <string>

namespace CBE
{
	struct Shader
	{
		enum Type
		{
			NONE = 0,
			VERT = 1,
			FRAG = 2
		};

		GLuint id;
		std::string fileName;
		std::string source;
		Type type;

		Shader(Type shaderType, const std::string& src, std::string name);
		~Shader();

		void Compile();
	};

	class ShaderProgram
	{
	public:
		ShaderProgram();
		~ShaderProgram();
		void AttachVertShader(Shader* vertShader);
		void AttachFragShader(Shader* fragShader);
		void Link();
		void Use();
		GLint GetUniformLocation(std::string& name);


		void Uniform1f(std::string name, GLfloat v0);
		void Uniform2f(std::string name, GLfloat v0, GLfloat v1);
		void Uniform3f(std::string name, GLfloat v0, GLfloat v1, GLfloat v2);
		void Uniform4f(std::string name, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
		void Uniform1i(std::string name, GLint v0);
		void Uniform2i(std::string name, GLint v0, GLint v1);
		void Uniform3i(std::string name, GLint v0, GLint v1, GLint v2);
		void Uniform4i(std::string name, GLint v0, GLint v1, GLint v2, GLint v3);
		void Uniform1ui(std::string name, GLuint v0);
		void Uniform2ui(std::string name, GLuint v0, GLuint v1);
		void Uniform3ui(std::string name, GLuint v0, GLuint v1, GLuint v2);
		void Uniform4ui(std::string name, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
		void Uniform1fv(std::string name, GLsizei count, const GLfloat* value);
		void Uniform2fv(std::string name, GLsizei count, const GLfloat* value);
		void Uniform3fv(std::string name, GLsizei count, const GLfloat* value);
		void Uniform4fv(std::string name, GLsizei count, const GLfloat* value);
		void Uniform1iv(std::string name, GLsizei count, const GLint* value);
		void Uniform2iv(std::string name, GLsizei count, const GLint* value);
		void Uniform3iv(std::string name, GLsizei count, const GLint* value);
		void Uniform4iv(std::string name, GLsizei count, const GLint* value);
		void Uniform1uiv(std::string name, GLsizei count, const GLuint* value);
		void Uniform2uiv(std::string name, GLsizei count, const GLuint* value);
		void Uniform3uiv(std::string name, GLsizei count, const GLuint* value);
		void Uniform4uiv(std::string name, GLsizei count, const GLuint* value);
		void UniformMatrix2fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix3fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix4fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix2x3fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix3x2fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix2x4fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix4x2fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix3x4fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
		void UniformMatrix4x3fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value);
	private:
		GLuint m_id;
		Shader* m_vertShader;
		Shader* m_fragShader;
		std::unordered_map<std::string, GLint> uniform_location;

	};
}

#endif

#include "App.h"

#include "Shader.h"
#include "spdlog/spdlog.h"

namespace CBE
{
	Shader::Shader(Type shaderType, const std::string& src, std::string name)
	{
		type = shaderType;
		source = src;
		fileName = name;
		switch (type) 
		{
			case VERT:
				id = glCreateShader(GL_VERTEX_SHADER);
				break;
			case FRAG:
				id = glCreateShader(GL_FRAGMENT_SHADER);
				break;
			case NONE:
			default:
				spdlog::error("Invalid shader type!");
				break;
		}
		const char* shader_src_c_str = source.c_str();
		glShaderSource(id, 1, &shader_src_c_str, NULL);
	}

	Shader::~Shader()
	{
		glDeleteShader(id);
	}

	void Shader::Compile()
	{
		int success;
		char infolog[512];
		glCompileShader(id);
		glGetShaderiv(id, GL_COMPILE_STATUS, &success);

		if(!success)
		{
			glGetShaderInfoLog(id, 512, NULL, infolog);
			spdlog::error("Failed to compile Shader {}! Reason: {}", fileName, infolog);
		}
	}

	ShaderProgram::ShaderProgram()
	{
		m_id = glCreateProgram();
	}

	ShaderProgram::~ShaderProgram()
	{
	}

	void ShaderProgram::AttachVertShader(Shader* vertShader)
	{
		m_vertShader = vertShader;
		glAttachShader(m_id, m_vertShader->id);
	}

	void ShaderProgram::AttachFragShader(Shader* fragShader)
	{
		m_fragShader = fragShader;
		glAttachShader(m_id, m_fragShader->id);
	}

	void ShaderProgram::Link()
	{
		int success;
		glLinkProgram(m_id);
		glGetProgramiv(m_id, GL_LINK_STATUS, &success);

		if(!success)
		{
			char infolog[512];
			glGetProgramInfoLog(m_id, 512, NULL, infolog);
			spdlog::error("Failed to link {} and {}. Reason:", m_vertShader->fileName, m_fragShader->fileName, infolog);
		}
	}

	void ShaderProgram::Use()
	{
		glUseProgram(m_id);
	}

	GLint ShaderProgram::GetUniformLocation(std::string& name)
	{
		if(uniform_location.contains(name)) return uniform_location[name];

		GLint location = glGetUniformLocation(m_id, name.c_str());
		uniform_location[name] = location;
		return location;
		
	}

		void ShaderProgram::Uniform1f(std::string name, GLfloat v0)
		{
			glUniform1f(GetUniformLocation(name), v0);
		}

		void ShaderProgram::Uniform2f(std::string name, GLfloat v0, GLfloat v1)
		{
			glUniform2f(GetUniformLocation(name), v0, v1);
		}

		void ShaderProgram::Uniform3f(std::string name, GLfloat v0, GLfloat v1, GLfloat v2)
		{
			glUniform3f(GetUniformLocation(name), v0, v1, v2);
		}

		void ShaderProgram::Uniform4f(std::string name, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3)
		{
			glUniform4f(GetUniformLocation(name), v0, v1, v2, v3);
		}

		void ShaderProgram::Uniform1i(std::string name, GLint v0)
		{
			glUniform1i(GetUniformLocation(name), v0);
		}

		void ShaderProgram::Uniform2i(std::string name, GLint v0, GLint v1)
		{
			glUniform2i(GetUniformLocation(name), v0, v1);
		}

		void ShaderProgram::Uniform3i(std::string name, GLint v0, GLint v1, GLint v2)
		{
			glUniform3i(GetUniformLocation(name), v0, v1, v2);
		}

		void ShaderProgram::Uniform4i(std::string name, GLint v0, GLint v1, GLint v2, GLint v3)
		{
			glUniform4i(GetUniformLocation(name), v0, v1, v2, v3);
		}

		void ShaderProgram::Uniform1ui(std::string name, GLuint v0)
		{
			glUniform1ui(GetUniformLocation(name), v0);
		}

		void ShaderProgram::Uniform2ui(std::string name, GLuint v0, GLuint v1)
		{
			glUniform2ui(GetUniformLocation(name), v0, v1);
		}

		void ShaderProgram::Uniform3ui(std::string name, GLuint v0, GLuint v1, GLuint v2)
		{
			glUniform3ui(GetUniformLocation(name), v0, v1, v2);
		}

		void ShaderProgram::Uniform4ui(std::string name, GLuint v0, GLuint v1, GLuint v2, GLuint v3)
		{
			glUniform4ui(GetUniformLocation(name), v0, v1, v2, v3);
		}

		void ShaderProgram::Uniform1fv(std::string name, GLsizei count, const GLfloat* value)
		{
			glUniform1fv(GetUniformLocation(name), count, value);
		}
		
		void ShaderProgram::Uniform2fv(std::string name, GLsizei count, const GLfloat* value)
		{
			glUniform2fv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform3fv(std::string name, GLsizei count, const GLfloat* value)
		{
			glUniform3fv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform4fv(std::string name, GLsizei count, const GLfloat* value)
		{
			glUniform4fv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform1iv(std::string name, GLsizei count, const GLint* value)
		{
			glUniform1iv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform2iv(std::string name, GLsizei count, const GLint* value)
		{
			glUniform2iv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform3iv(std::string name, GLsizei count, const GLint* value)
		{
			glUniform3iv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform4iv(std::string name, GLsizei count, const GLint* value)
		{
			glUniform4iv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform1uiv(std::string name, GLsizei count, const GLuint* value)
		{
			glUniform1uiv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform2uiv(std::string name, GLsizei count, const GLuint* value)
		{
			glUniform2uiv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform3uiv(std::string name, GLsizei count, const GLuint* value)
		{
			glUniform3uiv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::Uniform4uiv(std::string name, GLsizei count, const GLuint* value)
		{
			glUniform4uiv(GetUniformLocation(name), count, value);
		}

		void ShaderProgram::UniformMatrix2fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix2fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix3fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix3fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix4fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix4fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix2x3fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix2x3fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix3x2fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix3x2fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix2x4fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix2x4fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix4x2fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix4x2fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix3x4fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix3x4fv(GetUniformLocation(name), count, transpose, value);
		}

		void ShaderProgram::UniformMatrix4x3fv(std::string name, GLsizei count, GLboolean transpose, const GLfloat* value)
		{
			glUniformMatrix4x3fv(GetUniformLocation(name), count, transpose, value);
		}

}

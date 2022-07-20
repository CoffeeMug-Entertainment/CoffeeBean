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
}

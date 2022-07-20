#ifndef CBE_SHADER_H
#define CBE_SHADER_H

#include "glad/glad.h"
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
	private:
		GLuint m_id;
		Shader* m_vertShader;
		Shader* m_fragShader;

	};
}

#endif

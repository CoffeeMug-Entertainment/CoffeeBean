#ifndef CBE_DEFAULTSHADERS_H
#define CBE_DEFAULTSHADERS_H

#include <string>

namespace CBE
{
	const std::string DEFAULT_VERT_SHADER_SRC = R"glsl(
	#version 330 core

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec4 aColor;
	layout (location = 2) in vec2 aTexCoord;
	
	out vec4 vertColor;
	out vec2 texCoord;

	uniform mat4 transform;
	uniform mat4 projection;
	uniform mat4 view;
	uniform int ticks;

	void main()
	{
		gl_Position = projection * view * transform * vec4(aPos, 1.0);
		vertColor = aColor;
		texCoord = aTexCoord;
	}
	)glsl";

	const std::string DEFAULT_FRAG_SHADER_SRC = R"glsl(
	#version 330 core

	in vec4 vertColor;
	in vec2 texCoord;
	out vec4 FragColor;

	uniform mat4 transform;
	uniform mat4 projection;
	uniform mat4 view;
	uniform sampler2D aTexture;
	uniform int ticks;

	void main()
	{
		FragColor = texture(aTexture, texCoord) * vertColor;
	}
	)glsl";

	const std::string DEFAULT_VERT_LIGHT_SHADER_SRC = R"glsl(
	#version 330 core

	layout (location = 0) in vec3 aPos;

	uniform mat4 transform;
	uniform mat4 projection;
	uniform mat4 view;

	void main()
	{
		gl_Position = projection * view * transform * vec4(aPos, 1.0);
	}
	)glsl";

	const std::string DEFAULT_FRAG_LIGHT_SHADER_SRC = R"glsl(
	#version 330 core

	out vec4 FragColor;

	uniform vec3 objectColor;
	uniform vec3 lightColor;

	void main()
	{
		FragColor = vec4(1.0);
	}
	)glsl";
}

#endif

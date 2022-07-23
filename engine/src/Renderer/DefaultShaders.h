#ifndef CBE_DEFAULTSHADERS_H
#define CBE_DEFAULTSHADERS_H

#include <string>

namespace CBE
{
	const std::string DEFAULT_VERT_SHADER_SRC = R"glsl(
	#version 330 core

	layout (location = 0) in vec3 aPos;
	layout (location = 1) in vec4 aColor;
	out vec4 vertColor;

	uniform mat4 transform;
	uniform int ticks;

	void main()
	{
		gl_Position = transform * vec4(aPos, 1.0);
		vertColor = aColor;
	}
	)glsl";

	const std::string DEFAULT_FRAG_SHADER_SRC = R"glsl(
	#version 330 core

	in vec4 vertColor;
	out vec4 FragColor;

	uniform mat4 transform;
	uniform int ticks;

	void main()
	{
		FragColor = vertColor;
	}
	)glsl";
}

#endif

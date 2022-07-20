#ifndef CBE_DEFAULTSHADERS_H
#define CBE_DEFAULTSHADERS_H

#include <string>

namespace CBE
{
	const std::string DEFAULT_VERT_SHADER_SRC = R"glsl(
	#version 330 core

	layout (location = 0) in vec3 aPos;
	out vec4 vertColor;

	void main()
	{
		gl_Position = vec4(aPos, 1.0);
		vertColor = vec4(1.0, 1.0, 1.0, 1.0);
	}
	)glsl";

	const std::string DEFAULT_FRAG_SHADER_SRC = R"glsl(
	#version 330 core

	in vec4 vertColor;
	out vec4 FragColor;

	void main()
	{
		FragColor = vertColor;
		//FragColor = vec4(1.0, 1.0, 1.0, 1.0);
	}
	)glsl";
}

#endif

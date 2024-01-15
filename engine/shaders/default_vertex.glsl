#version 330 core

layout(location=0) in vec3 a_position;
layout(location=1) in vec2 a_uv;
//layout(location=1) in vec4 a_color;

out vec2 v_uv;
//out vec4 v_color;

uniform mat4 u_transform;

void main()
{
	gl_Position = u_transform * vec4(a_position, 1.0);
	v_uv = a_uv;
	//v_color = a_color;

}
#version 330 core

in vec2 v_uv;
out vec4 o_color;

uniform sampler2D u_text;

void main() 
{
	vec4 s = vec4(1.0, 1.0, 1.0, texture(u_text, v_uv).a);
	o_color = vec4(1.0, 1.0, 1.0, 1.0) * s;
}

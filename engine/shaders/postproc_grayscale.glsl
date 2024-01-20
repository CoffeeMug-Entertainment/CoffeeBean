#version 330 core

in vec2 v_uv;
out vec4 o_color;

uniform sampler2D u_screen_texture;

void main() 
{
	o_color = texture(u_screen_texture, v_uv);
	float y = o_color.r * 0.2126 + o_color.g * 0.7152 + o_color.b * 0.0722;
	o_color = vec4(y, y, y, 1.0);
}

#version 330 core

layout(location=0) in vec3 a_position;

uniform mat4 u_projection;

void main()
{
    gl_Position = u_projection * vec4(a_position.xyz, 1.0); 
}  
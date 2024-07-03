#version 330 core

layout(location=0) in vec4 a_position_uv;
out vec2 v_uv;

uniform mat4 u_projection;

void main()
{
    gl_Position = u_projection * vec4(a_position_uv.xy, 0.0, 1.0); 
    gl_Position.z = 0.0; //HACK(fhomolka): Something in the projection calculation causes it to be at -1.0. This is just a hacky fix
    v_uv = a_position_uv.zw;
}  
#version 330 core

layout(location = 0) in vec4 vertexPosition; //object space vertex position
layout(location = 1) in vec4 vertexTexCoord; //object space texture coordinates
uniform mat4 MVP;
uniform mat4 M;

out vec3 texCoord;

void main() {
    
    texCoord = (M * vertexTexCoord).xyz;
    gl_Position = MVP * vertexPosition;
    
}


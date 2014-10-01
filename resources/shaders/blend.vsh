#version 330 core

layout(location = 0) in vec4 vertexPosition; //object space vertex position
layout(location = 1) in vec4 vertextTexCoords; //object space vertex position
//uniform
uniform mat4 MVP;  //combined modelview projection matrix

smooth out vec2 vUV; //3D texture coordinates for texture lookup in the fragment shader

void main()
{
    //get the clipspace vertex position
    gl_Position = MVP*vertexPosition;

    //get the 3D texture coordinates by adding (0.5,0.5,0.5) to the object space
    //vertex position. Since the unit cube is at origin (min: (-0.5,-0.5,-0.5) and max: (0.5,0.5,0.5))
    //adding (0.5,0.5,0.5) to the unit cube object space position gives us values from (0,0,0) to
    //(1,1,1)
    vUV = vertextTexCoords.st;

}
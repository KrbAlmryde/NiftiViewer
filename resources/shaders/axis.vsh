#version 330 core

layout(location = 0) in vec4 vertexPosition;
layout(location = 1) in vec4 vertexColor;

uniform mat4 model;
smooth out vec4 theColors;

void main() {

  gl_Position = model * vertexPosition;
  theColors = vertexColor;

}

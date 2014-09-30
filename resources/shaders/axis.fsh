#version 330 core

layout(location = 0) out vec4 vFragColor; //fragment shader output

smooth in vec4 theColors;

void main() {

  vFragColor = theColors;//vec4(1.0,1.0,0.0,1.0);//colors;

}

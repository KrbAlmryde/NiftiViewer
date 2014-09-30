#version 330 core

layout(location = 0) out vec4 vFragColor; //fragment shader output

smooth in vec3 texCoord;  // 3D texture coordinates from the vertex shader



void main() {
    vFragColor = vec4(1.0);
}

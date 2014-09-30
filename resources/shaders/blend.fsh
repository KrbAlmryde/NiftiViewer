#version 330 core

layout(location = 0) out vec4 vFragColor; //fragment shader output

smooth in vec3 vUV;       //3D texture coordinates form vertex shader
                          //interpolated by rasterizer
//uniform samplers
uniform sampler3D   vVol0;     //volume dataset
uniform sampler3D   vVol1;     //volume dataset


/*****************************************************************************
 *                          Function Definitions                             *
 *****************************************************************************/


/*****************************************************************************
 *                               START OF MAIN                               *
 *****************************************************************************/
void main()
{
  vFragColor = vec4(0.0);

  vec4 brain = Texture(vVol0, vUV);
  vec4 clusters = Texture(vVol1, vUV);
  vec4 combined = mix(brain, clusters, 0.5);
  vFragColor = combined;
}

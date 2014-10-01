#version 330 core

layout(location = 0) out vec4 vFragColor; //fragment shader output

smooth in vec2 vUV;       //3D texture coordinates form vertex shader
                          //interpolated by rasterizer
//uniform samplers
uniform sampler2D   vVol0;     //volume dataset
uniform sampler2D   vVol1;     //volume dataset

// can also be uniform
const float partOf1 = 0.5f;

/*****************************************************************************
 *                          Function Definitions                             *
 *****************************************************************************/


/*****************************************************************************
 *                               START OF MAIN                               *
 *****************************************************************************/
void main()
{
  vFragColor = vec4(0.0);

    vec4 brain = texture(vVol0, vUV);//  * vec4(1.0f, 1.0f, 1.0f, partOf1);
    vec4 clusters = texture(vVol1, vUV);// * vec4(1.0f, 1.0f, 1.0f, 1.0f - partOf1);
    vec4 combined = brain + clusters; //mix(brain, clusters, 0.5);
  vFragColor = vec4(vUV.st,1,1);//combined;
}


//color = texture(texture1, texCoord) * vec4(1.0f, 1.0f, 1.0f, partOf1) + texture(texture2, texCoord) * vec4(1.0f, 1.0f, 1.0f, 1.0f - partOf1);
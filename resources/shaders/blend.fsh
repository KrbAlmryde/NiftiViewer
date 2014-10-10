#version 150

//uniform samplers
uniform sampler2D  vVol0;     //volume dataset
uniform sampler2D  vVol1;     //volume dataset

in vec2 texCoord;       //3D texture coordinates form vertex shader
out vec4 vFragColor; //fragment shader output

// can also be uniform
const float partOf1 = 0.5f;

/*****************************************************************************
 *                               START OF MAIN                               *
 *****************************************************************************/
void main()
{
    vFragColor = vec4(0.0);
    vec3 brain = vec3(texture(vVol0, texCoord.st).xyz);//  * vec4(1.0f, 1.0f, 1.0f, partOf1);
    vec3 clusters = vec3(texture(vVol1, texCoord.st).xyz);// * vec4(1.0f, 1.0f, 1.0f, 1.0f - partOf1);
    vFragColor = vec4(mix(brain, clusters, 0.5),1.0);
    // vFragColor = texture(vVol0, texCoord) * vec4(1.0f, 1.0f, 1.0f, partOf1) + texture(vVol1, texCoord) * vec4(1.0f, 1.0f, 1.0f, 1.0f - partOf1);
}


//color = 

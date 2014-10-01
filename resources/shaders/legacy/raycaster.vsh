#version 150

in vec3 vertexPosition; //object space vertex position

//uniform
uniform mat4 MVP;   //combined modelview projection matrix

smooth out vec3 vUV; //3D texture coordinates for texture lookup in the fragment shader


void main()
{  
	//get the clipspace position 
	gl_Position = MVP*vec4(vertexPosition.xyz,1);

	//get the 3D texture coordinates by adding (0.5,0.5,0.5) to the object space 
	//vertex position. Since the unit cube is at origin (min: (-0.5,-0.5,-0.5) and max: (0.5,0.5,0.5))
	//adding (0.5,0.5,0.5) to the unit cube object space position gives us values from (0,0,0) to 
	//(1,1,1)
	vUV = vertexPosition + vec3(0.5, 0.5, 0.5);
}
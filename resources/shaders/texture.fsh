#version 150

uniform sampler2D tex0;
in vec2 texCoord;
out vec4 outputFrag;

void main(){
    
    vec4 outColor1 = texture(tex0, texCoord.st);
    outputFrag = outColor1;
    //outputFrag = vec4(0.0,1.0,0.0, 1.0);
    
    
}

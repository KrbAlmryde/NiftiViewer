#version 330 core

out vec4 vFragColor = vec4(0.0);    //fragment shader output

smooth in vec3 vUV;             //3D texture coordinates form vertex shader
//interpolated by rasterizer

uniform vec3 camPos;     //camera position
uniform vec3 step_size;  //ray step size

uniform float alpha;

//pass in a color with alpha = 0 if not in use...
uniform vec4 vColor0;

// pass in the 3D sampler objects
uniform sampler3D   vVol0;     //volume dataset

uniform int MAX_SAMPLES; // = 154;    //total samples for each ray march step
uniform float DELTA;     //the step size for gradient calculation
uniform float iso;     // so we can play


//constants
const vec3 texMin = vec3(0);    //minimum texture access coordinate
const vec3 texMax = vec3(1);    //maximum texture access coordinate
float isoValue = iso/255.0; //the isovalue for iso-surface detection

struct nifti
{
 float before;
 float after;
 vec4 color;
};

/*****************************************************************************
*                          Function Definitions                             *
*****************************************************************************/


/*----------------------------------------------------------------------------
| function to give a more accurate position of where the given iso-value (iso)
| is found given the initial minimum limit (left) and maximum limit (right)
----------------------------------------------------------------------------*/
vec3 Bisection(vec3 left, vec3 right , float iso, sampler3D vol)
{
 //loop 4 times
 for(int i=0;i<4;i++)
 {
   //get the mid value between the left and right limit
   vec3 midpoint = (right + left) * 0.5;
   //sample the texture at the middle point
   float cM = texture(vol, midpoint).x ;
   //check if the value at the middle point is less than the given iso-value
   if(cM < iso)
     //if so change the left limit to the new middle point
     left = midpoint;
   else
     //otherwise change the right limit to the new middle point
     right = midpoint;
 }
 //finally return the middle point between the left and right limit
 return vec3(right + left) * 0.5;
}

/*----------------------------------------------------------------------------
| function to calculate the gradient at the given location in the volume dataset
| The function user center finite difference approximation to estimate the
| gradient
----------------------------------------------------------------------------*/
vec3 GetGradient(vec3 uvw, sampler3D vol)
{
 vec3 s1, s2;

 //Using center finite difference
 s1.x = texture(vol, uvw-vec3(DELTA,0.0,0.0)).x ;
 s2.x = texture(vol, uvw+vec3(DELTA,0.0,0.0)).x ;

 s1.y = texture(vol, uvw-vec3(0.0,DELTA,0.0)).x ;
 s2.y = texture(vol, uvw+vec3(0.0,DELTA,0.0)).x ;

 s1.z = texture(vol, uvw-vec3(0.0,0.0,DELTA)).x ;
 s2.z = texture(vol, uvw+vec3(0.0,0.0,DELTA)).x ;

 return normalize((s1-s2)/2.0);
}

/*----------------------------------------------------------------------------
| function to estimate the PhongLighting component given the light vector (L),
| the normal (N), the view vector (V), the specular power (specPower) and the
| given diffuse colour (diffuseColor). The diffuse component is first calculated
| Then, the half way vector is computed to obtain the specular component. Finally
| the diffuse and specular contributions are added together
----------------------------------------------------------------------------*/
vec4 PhongLighting(vec3 L, vec3 N, vec3 V, float specPower, vec3 diffuseColor)
{
 float diffuse = max(dot(L,N),0.0);
 vec3 halfVec = normalize(L+V);
 float specular = pow(max(0.00001,dot(halfVec,N)),specPower);
 return vec4((diffuse*diffuseColor + specular),1.0);
}


/*----------------------------------------------------------------------------
| N=surfacenormal, V=view direction, L=lightsource
----------------------------------------------------------------------------*/
vec4 hitIso ( vec3 dataPos, vec3 dirStep, vec3 geomDir, vec4 c_color, sampler3D tex)
{
 vec3 xN = dataPos;
 vec3 xF = dataPos+dirStep;

 //The view vector is simply opposite to the ray marching
 //direction
 vec3 V = -geomDir;

 //We keep the view vector as the light vector to give us a head
 //light
 vec3 L =  V;

 vec3 c1 = GetGradient(Bisection(xN, xF, isoValue, tex),tex);
 return PhongLighting(L,c1,V,250, c_color.rgb);

 //vFragColor.a = tp; //first iso cluster that we ran into opacity
}

/*----------------------------------------------------------------------------
 |
 |
 ----------------------------------------------------------------------------*/
vec4 getClusterColor(inout bool stop, vec4 cColor, vec4 vColor, sampler3D clust, vec3 pos, vec3 dstep, vec3 geomDir) {
   float before = texture(clust, pos).r - isoValue; //current sample
   float after = texture(clust, pos+dstep).r - isoValue; //next sample
   nifti nii = nifti(before, after, vColor);
   if(nii.color.a == 1.0 && !stop) {
     if( (nii.before) < 0  && (nii.after) >= 0.0)  {
       cColor = hitIso(pos, dstep, geomDir, nii.color, clust);
       stop = true;
     }
   }
 return cColor;
}



void main()
{
    vFragColor = vec4(0.0);

   //get the 3D texture coordinates for lookup into the volume dataset
   vec3 dataPos = vUV;

   //Gettting the ray marching direction:
   //get the object space position by subracting 0.5 from the
   //3D texture coordinates. Then subtraact it from camera position
   //and normalize to get the ray marching direction
   vec3 geomDir = normalize((vUV-vec3(0.5)) - camPos);

   //multiply the raymarching direction with the step size to get the
   //sub-step size we need to take at each raymarching step
   vec3 dirStep = geomDir * step_size;

   //flag to indicate if the raymarch loop should terminate
   //flag to indicate if the raymarch loop should terminate
   bool stop = false;

   //look for iso of clusters at timeA
   vec4 cCOLOR = vec4(0.0);

   for (int i = 0; i < MAX_SAMPLES; i++) {

       dataPos = dataPos + dirStep;

       if (dot(sign(dataPos-texMin),sign(texMax-dataPos)) < 3.0) {
           break;
       }

       if (!stop) {
           cCOLOR = getClusterColor(stop, cCOLOR, vColor0, vVol0, dataPos, dirStep, geomDir);
       }

       if (stop) { break; }
   }
   vFragColor = cCOLOR;
   vFragColor.a = alpha;
}
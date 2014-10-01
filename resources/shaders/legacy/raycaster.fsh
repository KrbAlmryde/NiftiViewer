#version 150

out vec4 vFragColor = vec4(0.0);    //fragment shader output

smooth in vec3 vUV;             //3D texture coordinates form vertex shader
                                //interpolated by rasterizer


uniform vec3        camPos;     //camera position
uniform vec3        step_size;  //ray step size

uniform float       brainOpacity;
uniform float       timePerc;

//pass in a color with alpha = 0 if not in use...
uniform vec4 c1_color;
uniform vec4 c2_color;
uniform vec4 c3_color;
uniform vec4 c4_color;
uniform vec4 c5_color;

//uniforms
uniform sampler3D   volume;     //volume dataset

uniform sampler3D   c1_tA;      //volume dataset
uniform sampler3D   c2_tA;      //volume dataset
uniform sampler3D   c3_tA;      //volume dataset
uniform sampler3D   c4_tA;      //volume dataset
uniform sampler3D   c5_tA;      //volume dataset

uniform sampler3D   c1_tB;      //volume dataset
uniform sampler3D   c2_tB;      //volume dataset
uniform sampler3D   c3_tB;      //volume dataset
uniform sampler3D   c4_tB;      //volume dataset
uniform sampler3D   c5_tB;      //volume dataset

//constants
const int MAX_SAMPLES = 300;    //total samples for each ray march step
const vec3 texMin = vec3(0);    //minimum texture access coordinate
const vec3 texMax = vec3(1);    //maximum texture access coordinate


// Function definition
// setColor(timePerc, clus1_tA, clus1_tB, c1_color)

bool setColor(in float timePerc, in vec4 c_tA, in vec4 c_tB, in vec3 c_color, out vec4 compColor) {
    float tA_o = 1.0 - (timePerc*2.0);
    float tB_o = timePerc*2.0;
    vec4 tA = vec4(c_color, tA_o);
    vec4 tB = vec4(c_color, tB_o);
    if (timePerc == 0.0) {
        if (c_tA.r > 0.0) {
            compColor = tA;
            return true;
        } else {
            compColor = vec4(0.0);
            return false;
        }
    } else if (timePerc < 0.5) {

        if (c_tA.r > 0.0 && c_tB.r > 0.0) {
            compColor = mix(tA, tB, tB_o);
            return true;

        } else if (c_tA.r > 0.0) {
            compColor = tA;
            return true;

        } else if (c_tB.r > 0.0) {
            compColor = tB;
            return true;

        } else {
            compColor = vec4(0.0);
            return false;
        }
    } else if (timePerc == 0.5) {
        if (c_tB.r > 0.0) {
            compColor = tB;
            return true;

        } else {
            compColor = vec4(0.0);
            return false;
        }

    } else { //}if (timePerc > 0.5) {
        tA_o = 1.0 - ((timePerc-0.5)*2.0);
        tB_o = (timePerc-0.5)*2.0;
        tA = vec4(c_color, tA_o);
        tB = vec4(c_color, tB_o);

        if (c_tA.r > 0.0 && c_tB.r > 0.0) {
          compColor = mix(tA, tB, tB_o);
          return true;
        } else if (c_tA.r > 0.0) {
          compColor = tA;
          return true;
        } else if (c_tB.r > 0.0) {
          compColor = tB;
          return true;
        } else {
          compColor = vec4(0.0);
          return false;
        }
    }
}


void main() {

    vec4 componentColor, componentColor1, componentColor2,
         componentColor3,  componentColor4, componentColor5;

    //get the 3D texture coordinates for lookup into the volume dataset
    vec3 dataPos = vUV;

    //Getting the ray marching direction:
    //get the object space position by subracting 0.5 from the
    //3D texture coordinates. Then subtraact it from camera position
    //and normalize to get the ray marching direction
    vec3 geomDir = normalize((vUV-vec3(0.5)) - camPos);

    //multiply the raymarching direction with the step size to get the
    //sub-step size we need to take at each raymarching step
    vec3 dirStep = geomDir * step_size;

    //flag to indicate if the raymarch loop should terminate
    bool stop = false;



    //for all samples along the ray
    for (int i = 0; i < MAX_SAMPLES; i++) {
        // advance ray by dirstep
        dataPos = dataPos + dirStep;


        //The two constants texMin and texMax have a value of vec3(-1,-1,-1)
        //and vec3(1,1,1) respectively. To determine if the data value is
        //outside the volume data, we use the sign function. The sign function
        //return -1 if the value is less than 0, 0 if the value is equal to 0
        //and 1 if value is greater than 0. Hence, the sign function for the
        //calculation (sign(dataPos-texMin) and sign (texMax-dataPos)) will
        //give us vec3(1,1,1) at the possible minimum and maximum position.
        //When we do a dot product between two vec3(1,1,1) we get the answer 3.
        //So to be within the dataset limits, the dot product will return a
        //value less than 3. If it is greater than 3, we are already out of
        //the volume dataset
        stop = dot(sign(dataPos-texMin),sign(texMax-dataPos)) < 3.0;

        //if the stopping condition is true we break out of the ray marching loop
        if (stop) { break; }

        // data fetching from the red channel of volume texture
        float sample = texture(volume, dataPos).r;

        if (sample > 0.0) {
            vec4 clust1_tA = texture(c1_tA, dataPos);
            vec4 clust2_tA = texture(c2_tA, dataPos);
            vec4 clust3_tA = texture(c3_tA, dataPos);
            vec4 clust4_tA = texture(c4_tA, dataPos);
            vec4 clust5_tA = texture(c5_tA, dataPos);

            vec4 clust1_tB = texture(c1_tB, dataPos);
            vec4 clust2_tB = texture(c2_tB, dataPos);
            vec4 clust3_tB = texture(c3_tB, dataPos);
            vec4 clust4_tB = texture(c4_tB, dataPos);
            vec4 clust5_tB = texture(c5_tB, dataPos);


            //Opacity calculation using compositing:
            //here we use front to back compositing scheme whereby the current sample
            //value is multiplied to the currently accumulated alpha and then this product
            //is subtracted from the sample value to get the alpha from the previous steps.
            //Next, this alpha is multiplied with the current sample colour and accumulated
            //to the composited colour. The alpha value from the previous steps is then
            //accumulated to the composited colour alpha.
            float prev_alpha = sample - (sample * vFragColor.a);

            vFragColor.rgb = prev_alpha * vec3(sample) + vFragColor.rgb;

            if (c1_color.a == 1.0 && c2_color.a == 1.0 && c3_color.a == 1.0 && c4_color.a == 1.0 &&  c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor3.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;
              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0 && c3_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor3.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0 && c3_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor3.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0 && c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c3_color.a == 1.0 && c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor3.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c3_color.a == 1.0 && c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor3.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0 && c3_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor3.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c3_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor3.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c3_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor3.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c3_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor3.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c3_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor3.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c3_color.a == 1.0 && c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor3.rgb + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c2_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor2.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c3_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor3.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c3_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor3.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c3_color.a == 1.0 && c4_color.a == 1.0) {
              if(setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor3.rgb + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c3_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor3.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c4_color.a == 1.0 && c5_color.a == 1.0) {
              if(setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4) ||
                 setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor4.rgb + componentColor5.rgb + vFragColor.rgb;

              }
            }
            else if (c1_color.a == 1.0) {
              if(setColor(timePerc, clust1_tA, clust1_tB, c1_color.rbg, componentColor1)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor1.rgb + vFragColor.rgb;

              }
            }
            else if (c2_color.a == 1.0) {
              if(setColor(timePerc, clust2_tA, clust2_tB, c2_color.rbg, componentColor2)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor2.rgb + vFragColor.rgb;

              }
            }
            else if (c3_color.a == 1.0) {
              if(setColor(timePerc, clust3_tA, clust3_tB, c3_color.rbg, componentColor3)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor3.rgb + vFragColor.rgb;

              }
            }
            else if (c4_color.a == 1.0) {
              if(setColor(timePerc, clust4_tA, clust4_tB, c4_color.rbg, componentColor4)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor4.rgb + vFragColor.rgb;

              }
            }
            else if (c5_color.a == 1.0) {
              if(setColor(timePerc, clust5_tA, clust5_tB, c5_color.rbg, componentColor5)) {
                  vFragColor.rgb = prev_alpha * vec3(sample) + componentColor5.rgb + vFragColor.rgb;

              }
            }

            vFragColor.a += prev_alpha;

            //early ray termination
            //if the currently composited colour alpha is already fully saturated
            //we terminated the loop
            if( vFragColor.a>0.99) {
                break;
            }
        }
    }

    //vFragColor = vFragColor.rrra;
    vFragColor.a *= brainOpacity;
}

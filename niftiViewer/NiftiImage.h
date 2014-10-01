//
// Created by Kyle Almryde on 2/27/14.
// Copyright (c) 2014 Angus Forbes. All rights reserved.
//


#ifndef __NIFTIIMAGE_H_
#define __NIFTIIMAGE_H_


#include <Aluminum/Aluminum.h>
#include "nifti1_io.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MIN_HEADER_SIZE 348
#define NII_HEADER_SIZE 352
//END NIFTI stuff...


using std::string;
using glm::vec4;
using namespace aluminum;

class NiftiImage {

public:

    struct Model {
        vector<float> onsets;
        float min, max;  // min and max values
    };

    znzFile fp;
    nifti_1_header hdr;
    Texture texture;
    Model model;
    vec4 color;

//    nifti_1_header *hdr;
    nifti_image *nim;
    

    NiftiImage(); // In case no parameters exist;

    NiftiImage(string fname);  // This calls the niftiUtils function to load a nifti File into a texture
    NiftiImage(string fname, glm::vec4 rgba);  // This calls the niftiUtils function to load a nifti File into a texture
    NiftiImage(string image_name, string model_name);  // This calls the niftiUtils function to load a nifti File into a texture
    NiftiImage(string image_name, string model_name,glm::vec4 rgba);  // This calls the niftiUtils function to load a nifti File into a texture


    void load3DTexture(string fname);   // manually attach a texture
    void loadModel(string fname);

    void update(string image_name, string model_name);
    void updateTexture(string image_name);

    // simple wrappers to call Texture's bind() and unbind() methods
    void bind(GLenum textureUnit);
    void unbind(GLenum textureUnit);

    void destroy();

    void setColor(float r, float g, float b, float a);
    void setColor(glm::vec4 rgba);

protected:
    ResourceHandler rh;
    void loadVector(string name);
    int read_nifti_file(string fname);
    template<class T> int load_nifti_texture(znzFile fp, nifti_image *nim, Texture &tex);
    /*=============================
     *    load_nifti_texture()    *
     =============================*/
};

#endif //__NIFTIIMAGE_H_

//
// Created by Kyle Almryde on 2/27/14.
// Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#include "NiftiImage.h"
#include <numeric>

NiftiImage::NiftiImage() {};

/*
 These two functions were taken from this thread via Stack Overflow, very helpful!
 http://stackoverflow.com/questions/236129/how-to-split-a-string-in-c
 */
std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
    std::stringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}

std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> elems;
    split(s, delim, elems);
    return elems;
}

/*
 And this thread helped with this function...
 http://stackoverflow.com/questions/9277906/stdvector-to-string-with-custom-delimiter
 */
std::string join(const vector<std::string> vec, const std::string delim="."){
    stringstream s;
    copy(vec.begin(),vec.end(),std::ostream_iterator<std::string>(s,delim.c_str()));
    std::string result = s.str();
    result.pop_back();
    return result;
}


void assignName(vector<std::string> tokens, std::string &name, std::string &type){
    if(tokens.back() == "gz")
        type = "nii.gz";
    else if(tokens.back() == "gz")
        type = "nii";
    else if(tokens.back() == "1D")
        type = "1D";

    name = tokens[0];
    printf("\n In assignName...%s.%s\n",name.c_str(), type.c_str());
}

// This calls the niftiUtils function to load a nifti File into a texture
NiftiImage::NiftiImage(string fname) {
    std::string type, name;
    vector<string> tokens = split(fname, '.');
    assignName(tokens, name, type);
    printf("\n In assignName...%s.%s\n",name.c_str(), type.c_str());
    read_nifti_file(rh.pathToResource(name, type));
}

NiftiImage::NiftiImage(string fname, glm::vec4 rgba) {
    std::string type, name;
    vector<string> tokens = split(fname, '.');
    assignName(tokens, name, type);
    read_nifti_file(rh.pathToResource(name, type));
    setColor(rgba);
}


// This calls the niftiUtils function to load a nifti File into a texture
NiftiImage::NiftiImage(string image_name, string model_name){
    vector<string> tokens = split(image_name, '.');
    std::string image_type = tokens.back(); tokens.pop_back();
    std::string img_name = join(tokens);
    read_nifti_file(rh.pathToResource(img_name, image_type));

    tokens.clear();
    tokens = split(model_name, '.');
    std::string model_type = tokens.back(); tokens.pop_back();
    std::string model = join(tokens);
    loadVector(rh.pathToResource(model,model_type));
}


NiftiImage::NiftiImage(string image_name, string model_name, glm::vec4 rgba) {
    vector<string> tokens = split(image_name, '.');
    std::string image_type = tokens.back(); tokens.pop_back();
    std::string img_name = join(tokens);
    read_nifti_file(rh.pathToResource(img_name, image_type));

    tokens.clear();
    tokens = split(model_name, '.');
    std::string model_type = tokens.back(); tokens.pop_back();
    std::string model = join(tokens);
    loadVector(rh.pathToResource(model,model_type));
    setColor(rgba);
}

void NiftiImage::load3DTexture(string fname){
    vector<string> tokens = split(fname, '.');
    std::string type = tokens.back(); tokens.pop_back();
    std::string name = join(tokens);
    read_nifti_file(rh.pathToResource(name, type));
}

void NiftiImage::loadModel(string fname) {
    vector<string> tokens = split(fname, '.');
    std::string type = tokens.back(); tokens.pop_back();
    std::string name = join(tokens);
    loadVector(rh.pathToResource(name,type));
}

void NiftiImage::update(string image_name, string model_name){
    destroy();

    vector<string> tokens = split(image_name, '.');
    std::string image_type = tokens.back(); tokens.pop_back();
    std::string img_name = join(tokens);
    read_nifti_file(rh.pathToResource(img_name, image_type));

    tokens.clear();
    tokens = split(model_name, '.');
    std::string model_type = tokens.back(); tokens.pop_back();
    std::string model = join(tokens);

    read_nifti_file(rh.pathToResource(image_name, image_type));
    loadVector(rh.pathToResource(model_name,model_type));
}

void NiftiImage::updateTexture(string image_name){
    destroy();
    vector<string> tokens = split(image_name, '.');
    std::string image_type = tokens.back(); tokens.pop_back();
    std::string img_name = join(tokens);

    destroy();
    read_nifti_file(rh.pathToResource(img_name, image_type));

}


void NiftiImage::bind(GLenum textureUnit){

    texture.bind(textureUnit); //    glDeleteTextures(0, (GLuint const*)texture.id());

}

void NiftiImage::unbind(GLenum textureUnit){
    texture.unbind(textureUnit); //    glDeleteTextures(0, (GLuint const*)texture.id());
}

void NiftiImage::destroy(){
    texture.destroy(); //    glDeleteTextures(0, (GLuint const*)texture.id());
}

void NiftiImage::setColor(float _r, float _g, float _b, float _a){
    color.r = _r;
    color.g = _g;
    color.b = _b;
    color.a = _a;
}


void NiftiImage::setColor(glm::vec4 rgba){
    color = rgba;
}

void NiftiImage::loadVector(string name) {
    ifstream infile(name);
    if(infile){
        float value = 0.0;
        model.min = 0.0;
        model.max = 0.0;
        while(infile >> value){
            if (value > model.max) model.max = value;
            else if (value < model.min) model.min = value;
            model.onsets.push_back(value);
        }
    }
    infile.close();
}

/*=============================
 *      read_nifti_file()     *
 =============================*/
int NiftiImage::read_nifti_file(string fname) {

    nifti_image * nim = nifti_image_read(fname.c_str(), 1);
    znzFile fp = znzopen(nim->iname, "rb", nifti_is_gzfile(nim->iname));

    if (!nim)
        exit(1);

    nifti_image_infodump(nim);

    /** save to 3D Texture **/
    switch (nim->datatype) {
        case 2:
            load_nifti_texture<unsigned char>(fp, nim, texture);
            break;
        case 4:
            load_nifti_texture<signed short>(fp, nim, texture);
            break;
        case 8:
            load_nifti_texture<signed int>(fp, nim, texture);
            break;
        case 16:
            load_nifti_texture<float>(fp, nim, texture);
            break;
        case 64:
            load_nifti_texture<double>(fp, nim, texture);
            break;
        default :
            printf("data type %d is not supported... exiting...\n", nim->datatype);
            exit(1);
    }

    return 0;
}


template<class T> int NiftiImage::load_nifti_texture(znzFile fp, nifti_image *nim, Texture &tex){

    int i;
    int max = 0;
    double total = 0.0;
    unsigned long ret;

    T *data = (T *) malloc(sizeof(T) * nim->nvox);  // Allocate memory for nifti image data
    GLubyte *oneVolume = (GLubyte *) malloc(sizeof(GLubyte) * nim->nvox);  // Allocate memory for Texture

    if (data == NULL) {  // Make sure data is not NULL, otherwise exit.
        fprintf(stderr, "\nError allocating data buffer\n"); // for %s\n",data_file.c_str());
        exit(1);
    }

    if (znzseek(fp, nim->iname_offset, 0) < 0) { // Position file point to actual data based on image offset
        fprintf(stderr,"** could not seek to offset %u in file '%s'\n", (unsigned)nim->iname_offset, nim->iname);
        exit(1);
    }

    ret = znzread(data, sizeof(T), nim->nvox, fp);  // read in data

    if (ret != nim->nvox) { // make sure all data was read in correctly
        fprintf(stderr, "error loading volume data from file...\n");
        exit(1);
    } else {
        printf("ret = %ld,  size = %zu\n", ret, nim->nvox);
        znzclose(fp);
    }


    for (i = 0; i < nim->nvox; i++) {
        total += data[i];
        if (data[i] > max){
            max = data[i];
        }
    }

    int idx = 0;
    for (i = 0; i < nim->nvox; i++) {
        oneVolume[idx++] = (GLubyte) (((float) data[i] / (float) max) * 255);
    }

    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    tex = Texture(oneVolume, nim->dim[1], nim->dim[2], nim->dim[3], GL_RGBA, GL_RED, GL_UNSIGNED_BYTE);
    tex.wrapMode(GL_CLAMP_TO_EDGE);
    tex.minFilter(GL_LINEAR);
    tex.maxFilter(GL_LINEAR);

    free(data);
    free(oneVolume);
    nifti_image_free(nim);

    return 0;
}




//
// Created by Kyle Almryde on 2/27/14.
// Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#include "NiftiImage.h"
#include <numeric>

template <typename T>
using nii = std::pair<std::string, T>;


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

const Texture &NiftiImage::operator [](int idx) const {
    return texture[idx];
}

Texture &NiftiImage::operator [](int idx) {
    return texture[idx];
}


NiftiImage::NiftiImage() {};

// This calls the niftiUtils function to load a nifti File into a texture
NiftiImage::NiftiImage(string fname) {
    vector<string> tokens = split(fname, '.');
    std::string type = tokens.back(); tokens.pop_back();
    std::string name = join(tokens);
    printf("%s.%s",name.c_str(), type.c_str());
//    read_nifti_file(rh.pathToResource(name, type));

    // temporarilly refer to nifti images on the desktop instead of copying them to the bundle
    string PATHTOFILE = "/Users/krbalmryde/Desktop/nifti/";
    read_nifti_file(PATHTOFILE + fname);
}

NiftiImage::NiftiImage(string fname, glm::vec4 rgba) {
    vector<string> tokens = split(fname, '.');
    std::string type = tokens.back(); tokens.pop_back();
    std::string name = join(tokens);
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
    loadVector(rh.pathToResource(model,model_type));    setColor(rgba);
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
    for(auto& tex:texture){
        tex.bind(textureUnit); //    glDeleteTextures(0, (GLuint const*)texture.id());
    }
}

void NiftiImage::unbind(GLenum textureUnit){
    for(auto& tex:texture){
        tex.unbind(textureUnit); //    glDeleteTextures(0, (GLuint const*)texture.id());
    }
}

void NiftiImage::destroy(){
    for(auto& tex:texture){
        tex.destroy(); //    glDeleteTextures(0, (GLuint const*)texture.id());
    }
    texture.clear();  // Clear the memory stores
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


void NiftiImage::hdrDump(){
//    print_nifti_header_info();
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

void NiftiImage::print_nifti_header_info() {
    /* print a little header information */
    fprintf(stderr, "\nXYZT dimensions: %d %d %d %d", hdr.dim[1], hdr.dim[2], hdr.dim[3], hdr.dim[4]);
    fprintf(stderr, "\nDatatype code and bits/pixel: %d %d", hdr.datatype, hdr.bitpix);
    fprintf(stderr, "\nScaling slope and intercept: %.6f %.6f", hdr.scl_slope, hdr.scl_inter);
    fprintf(stderr, "\nByte offset to data in datafile: %ld", (long) (hdr.vox_offset));
    fprintf(stderr, "\n");
}


void NiftiImage::open_nifti_header(std::string data_file) {
    /********** open and read header */
    fp = znzopen(data_file.c_str(), "r", 0);
    if (znz_isnull(fp)) {
        perror(data_file.c_str());
        fprintf(stderr, "\nError opening header file %p\n", data_file.c_str());
        exit(1);
    }
}

void NiftiImage::read_nifti_header(std::string data_file) {
    long ret;
    //read header data
    ret = znzread(&hdr, MIN_HEADER_SIZE, 1, fp);
    if (ret != 1) {
        perror(data_file.c_str());
        fprintf(stderr, "\nError reading header file %p\n", data_file.c_str());
        exit(1);
    }

    printf("In read_nifti_header! vox_offset is %f", hdr.vox_offset);
    //move file pointer to end of header data
    if(hdr.vox_offset < 0)
        ret = znzseek(fp, (long) (-1*hdr.vox_offset), SEEK_SET);
    else
        ret = znzseek(fp, (long) (hdr.vox_offset), SEEK_SET);

    if (ret != 0) {
        perror(data_file.c_str());
        fprintf(stderr, "\nError doing znzseek() to %ld in data file %p\n", (long) (hdr.vox_offset), data_file.c_str());
        exit(1);
    }
}


int NiftiImage::read_nifti_file(std::string data_file) {
//    hdr = nifti_read_header(data_file.c_str(), 0, 1);
//    fp = nifti_image_open(data_file.c_str(), (char *) "rb", &nim);
    open_nifti_header(data_file);
    read_nifti_header(data_file);
    print_nifti_header_info();


    switch (hdr.datatype) {
        case 2 :
            return read_nifti_data<unsigned char>(fp, hdr, texture);
        case 4 :
            return read_nifti_data<signed short>(fp, hdr, texture);
        case 8 :
            return read_nifti_data<signed int>(fp, hdr, texture);
        case 16 :
            return read_nifti_data<float>(fp, hdr, texture);
        default :
            printf("data type %d is not supported... exiting...\n", hdr.datatype);
            exit(1);
    }
}

//template<class T> static int do_stuff(nifti_image &nim, vector<Texture> &tex) {
//
//    size_t nBytesPerVol = nifti_get_volsize(&nim);
//    int i, total, step, vol, max = 0;
//    /********** print mean of data */
//
//    for (vol = 0; vol < nim.dim[4]; vol++){
//        if (vol >= 10) {
//            nifti_image_unload(&nim);
//            return(0);
//        }
//
//        total = 0;
//        step = 0;
//        max = 0;
//
//        for (i = step; i < nBytesPerVol*(vol+1); i++) {
//            total += data[i];
//            if (data[i] > max) {
//                printf("%d\n", data[i]);
//                max = data[i];
//            }
//        }
////            total /= (hdr.dim[1] * hdr.dim[2] * hdr.dim[3] * hdr.dim[4]);
//
//        /** save to 3D Texture **/
//        GLubyte *oneVolume = (GLubyte *) malloc(sizeof(GLubyte) * (nim.nvox));
//
//        int idx = 0;
//        for (i = step; i < nBytesPerVol*(vol+1); i++) {
//            if ( ( (float) max / (float) data[i] ) < 80.00) // Trying to filter data
//                oneVolume[idx++] = (GLubyte) (((float) data[i] / (float) max) * 255);
//            else
//                oneVolume[idx++] = (GLubyte) 0.0;
//        }
//
//        glPixelStorei(GL_PACK_ALIGNMENT, 1);
//        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
////            tex.push_back(Texture(oneVolume, hdr.dim[1], hdr.dim[2], hdr.dim[3], GL_RGBA, GL_RED, GL_FLOAT));
//        tex.push_back(Texture(oneVolume, nim.dim[1], nim.dim[2], nim.dim[3], GL_RGBA, GL_RED, GL_UNSIGNED_BYTE));
//        tex[vol].minFilter(GL_LINEAR);
//        tex[vol].maxFilter(GL_LINEAR);
//        step += nim.nvox;
//    }
//    nifti_image_unload(&nim);
//    return(0);
//}

//
//template<typename T>
//int load_nifti_texture(T &data, nifti_image *nim, vector<Texture> &tex)
//{
//    printf("Made it to load_nifti_texture!!!\n Working with %s\n",nim->iname);
//
//    int i, total, step, vol, max;
//    size_t nBytesPerVol = (size_t) nim->dim[1] * nim->dim[2] * nim->dim[3]; //nifti_get_volsize(nim);
//
////    for (vol = 0; vol < nim->dim[4]; vol++){
////        if (vol >= 10) {
////            nifti_image_unload(nim);
////            return(0);
////        }
////
////    }
//    total = 0;
////    step = 0;
//    max = 0;
//
//    for (i = 0; i <  nBytesPerVol ; i++) {
//        total += data[i];
//        if (data[i] > max) {
//            printf("%d\n", data[i]);
//            max = data[i];
//        }
//        printf("%d\t%d\n", max, data[i]);
//    }
////            total /= (hdr.dim[1] * hdr.dim[2] * hdr.dim[3] * hdr.dim[4]);
//
//    /** save to 3D Texture **/
//    GLubyte *oneVolume = (GLubyte *) malloc(sizeof(GLubyte) * (nim->nvox));
//
//    int idx = 0;
//    for (i = 0; i < nBytesPerVol*(vol+1); i++) {
//        float voxelValue = ( data[i]/ (float) max );
//        oneVolume[idx++] = (GLubyte) (voxelValue < 80.00 ? (voxelValue * 255)+2 : 1.0);
//    }
//
//    glPixelStorei(GL_PACK_ALIGNMENT, 1);
//    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
////            tex.push_back(Texture(oneVolume, hdr.dim[1], hdr.dim[2], hdr.dim[3], GL_RGBA, GL_RED, GL_FLOAT));
//
//    tex.push_back(Texture(oneVolume, nim->dim[1], nim->dim[2], nim->dim[3], GL_RGBA, GL_RED, GL_UNSIGNED_BYTE));
//    tex[vol].minFilter(GL_LINEAR);
//    tex[vol].maxFilter(GL_LINEAR);
//
////    step += nim->nvox;
//    nifti_image_unload(nim);
//    return(0);
//}


//int NiftiImage::read_nifti_file(std::string data_file) {
//
//    printf("Made it to read_nifti_file!!\n");
//    hdr = nifti_read_header(data_file.c_str(), 0, 1);
//    fp = nifti_image_open(data_file.c_str(), (char *) "rb", &nim);
//
//    size_t nBytesPerVol = nifti_get_volsize(nim);
//
//    if(nifti_image_load(nim)==1) exit(1);
//
//    if (nim->datatype == 2){
//        unsigned char* data = (unsigned char*) malloc(sizeof(unsigned char*) * nBytesPerVol);
//        return load_nifti_texture(data, nim, texture);
//
//    } else if (nim->datatype == 4){
//        signed short* data = (signed short*) malloc(sizeof(signed short*) * nBytesPerVol);
//        return load_nifti_texture(data, nim, texture);
//
//    } else if (nim->datatype == 8){
//        signed int* data = (signed int*)malloc(sizeof(signed int*) * nBytesPerVol);
//        return load_nifti_texture(data, nim, texture);
//
//    } else if (nim->datatype == 16){
//        float* data = (float*)malloc(sizeof(float*) * nBytesPerVol);
//        return load_nifti_texture(data, nim, texture);
//
//    } else if (nim->datatype == 64){
//        double* data = (double*)malloc(sizeof(double*) * nBytesPerVol);
//        return load_nifti_texture(data, nim, texture);
//
//    } else {
//        printf("Whoa! data type %d is not supported... exiting...\n", hdr->datatype);
//        exit(1);
//
//    }
//}

//    switch(nim->datatype){
//
//        case 2 :
//            return load_nifti_texture((unsigned char*)malloc(sizeof(unsigned char) * nBytesPerVol), nim, texture);
//        case 4:
//            return load_nifti_texture((signed short*)malloc(sizeof(signed short) * nBytesPerVol), nim, texture);
//        case 8:
//            return load_nifti_texture((signed int*)malloc(sizeof(signed int) * nBytesPerVol), nim, texture);
//        case 16:
//            return load_nifti_texture((float*)malloc(sizeof(float) * nBytesPerVol), nim, texture);
//        case 64:
//            return load_nifti_texture((double*)malloc(sizeof(double) * nBytesPerVol), nim, texture);
//        default:
//          printf("Whoa! data type %d is not supported... exiting...\n", hdr->datatype);
//          exit(1);
//    }



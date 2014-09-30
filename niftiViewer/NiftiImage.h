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
    vector<Texture> texture;
    Model model;
    vec4 color;

//    nifti_1_header *hdr;
    nifti_image *nim;
    

    NiftiImage(); // In case no parameters exist;

    NiftiImage(string fname);  // This calls the niftiUtils function to load a nifti File into a texture
    NiftiImage(string fname, glm::vec4 rgba);  // This calls the niftiUtils function to load a nifti File into a texture
    NiftiImage(string image_name, string model_name);  // This calls the niftiUtils function to load a nifti File into a texture
    NiftiImage(string image_name, string model_name,glm::vec4 rgba);  // This calls the niftiUtils function to load a nifti File into a texture

    Texture& operator[](int idx);
    const Texture& operator[](int idx) const;

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

    void hdrDump();


protected:
    ResourceHandler rh;
    void loadVector(string name);

    int read_nifti_file(string data_file);

    void print_nifti_header_info();
    void open_nifti_header(std::string data_file);
    void read_nifti_header(std::string data_file);
    
    template<class T> static int load_nifti_texture(znzFile fp, nifti_image *nim, Texture &tex);
    /*=============================
     *    load_nifti_texture()    *
     =============================*/
    template<class T> static int load_nifti_texture(znzFile fp, nifti_image *nim, Texture &tex){

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


        /** save to 3D Texture **/

//        printf("value of data: %zu\n", data);

//            Texture tex;
//            znzFile fp;
//            unsigned long ret;
//
//            T *data = (T *) malloc(nifti_get_volsize(nim));
//            GLubyte *oneVolume = (GLubyte *) malloc(sizeof(GLubyte) * (nim->nvox));
//
//            fp = znzopen(nim->iname, "rb", nifti_is_gzfile(nim->iname));
//            ret = znzread(data, sizeof(T), nim->nvox, fp);
//            printf("ret = %ld,  size = %zu\n", ret, nim->nvox);
//            znzclose(fp);


//        if(nim->scl_slope != 0.0){
//            printf("Used scl_slope, was %f, for %s\n", nim->scl_slope, nim->iname);
//            for (int i = 0; i < nim->nvox; i++) {
//                // printf("Allocating data! %f\n",data[i]);
//                oneVolume[i] = (GLubyte) ((data[i] * nim->scl_slope) + nim->scl_inter) * 255;
//            }
//            printf("Allocating data! %f\n",oneVolume[nim->nvox-1]);
//        } else {
//            for (int i = 0; i < nim->nvox; i++) {
//                if (data[i] > max){
//                    max = data[i];
//                }
//            }
//            for (int i = 0; i < nim->nvox; i++) {
////                printf("Allocating data! %f\n",data[i]);
//                oneVolume[i] = ((GLubyte) ((float) data[i] / (float) max) * 255);
//            }
//            printf("Allocating data! %f\n",oneVolume[nim->nvox-1]);
//            printf("Used Max! Was %f, for %s\n", max, nim->iname);
//        }
//        if(nim->scl_slope != 0.0){
//            printf("Used scl_slope, was %f, for %s\n", nim->scl_slope, nim->iname);
//            for (int i = 0; i < nim->nvox; i++) {
//                // printf("Allocating data! %f\n",data[i]);
//                oneVolume[i] = (GLubyte) ((data[i] * nim->scl_slope) + nim->scl_inter) * 255;
//            }
//            printf("Allocating data! %f\n",oneVolume[nim->nvox-1]);
//        }
//
//        tex = Texture(oneVolume, nim->dim[1], nim->dim[2], nim->dim[3], GL_RGBA, GL_RED, GL_UNSIGNED_BYTE);
//


        return 0;
    }



//    template<class T> static int read_nifti_data(znzFile fp, nifti_1_header hdr, vector<Texture> &tex) {


//        T *data = NULL;

//        int nBytesPerVol = hdr.dim[1] * hdr.dim[2] * hdr.dim[3];
//        int nBytesTotal = hdr.dim[1] * hdr.dim[2] * hdr.dim[3] * hdr.dim[4];

//        int i;
//        int max = 0;
//        double total = 0;
//        unsigned long ret;

//        data = (T *) malloc(sizeof(T) * nBytesPerVol);

//        if (data == NULL) {
//            fprintf(stderr, "\nError allocating data buffer\n"); // for %s\n",data_file.c_str());
//            exit(1);
//        }

//        ret = znzread(data, sizeof(T), (size_t) nBytesTotal, fp);

//        printf("ret = %ld,  size = %d\n", ret, nBytesTotal);
//        if (ret != nBytesTotal) {
//            fprintf(stderr, "error loading volume data from file...\n");
//            exit(1);
//        }

//        znzclose(fp);

//        /********** scale the data buffer  */

//         if (hdr.scl_slope != 0) {
//             for (i=0; i<nBytesPerVol; i++)
//                 data[i] = (data[i] * hdr.scl_slope) + hdr.scl_inter;
//         }

//        for (i = 0; i < nBytesPerVol; i++) {
//            total += data[i];
//            if (data[i] > max) {
//                printf("%f\n", data[i]);
//                max = data[i];
//            }
//        }

//        /** save to 3D Texture **/
//        GLubyte *oneVolume = (GLubyte *) malloc(sizeof(GLubyte) * (nBytesPerVol));

//        int idx = 0;
// //       for (i = step; i < nBytesPerVol*(vol+1); i++) {
//        for (i = 0; i < nBytesPerVol; i++) {
//            float voxelValue = ( (float) data[i]/ (float) max );
//            oneVolume[idx++] = (GLubyte)(voxelValue * 255); //(GLubyte) (voxelValue >= 80.00 ? (voxelValue * 255) : 0.0);

//        }

//        glPixelStorei(GL_PACK_ALIGNMENT, 1);
//        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//        tex.push_back(Texture(oneVolume, hdr.dim[1], hdr.dim[2], hdr.dim[3], GL_RGBA, GL_RED, GL_UNSIGNED_BYTE));
//        tex[0].minFilter(GL_LINEAR);
//        tex[0].maxFilter(GL_LINEAR);
// //       step += nBytesPerVol;
//        free(oneVolume);
//        free(data);
//        return (0);
//    };

};
#endif //__NIFTIIMAGE_H_

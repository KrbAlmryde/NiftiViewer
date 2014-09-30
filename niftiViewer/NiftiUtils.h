// Utility to write NIFTI data to a OpenGL texture
// read_nifti_file(std::string data_file, Texture& t, int dataType) is the only public function

#include <Aluminum/Aluminum.h>
//#import "Includes.hpp"
//#import "Texture.hpp"

//NIFTI stuff...

#include "nifti1.h"
#include "nifti1_io.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//typedef signed short MY_DATATYPE;
//typedef unsigned char MY_DATATYPE;
#define MIN_HEADER_SIZE 348
#define NII_HEADER_SIZE 352
//END NIFTI stuff...

using namespace aluminum;

class NiftiUtils {
public:

    static int read_nifti_file(std::string data_file, Texture &t) {

        FILE *fp = open_nifti_header(data_file);

        nifti_1_header hdr = read_nifti_header(data_file, fp);

        print_nifti_header_info(hdr);

        switch (hdr.datatype) {
            case 2 :
                return read_3d_nifti_data<unsigned char>(fp, hdr, t);
            case 4 :
                return read_3d_nifti_data<signed short>(fp, hdr, t);
            case 8 :
                return read_3d_nifti_data<signed int>(fp, hdr, t);
            case 16 :
                return read_3d_nifti_data<float>(fp, hdr, t);
            default :
                printf("data type %d is not supported... exiting...\n", hdr.datatype);
                exit(1);
        }
    }


private:

    template<class T> static int read_3d_nifti_data(FILE *fp, nifti_1_header hdr, Texture &tex) {
        T *data = NULL;

        unsigned long ret;
        int i;
        double total;

        data = (T *) malloc(sizeof(T) * hdr.dim[1] * hdr.dim[2] * hdr.dim[3]);

        if (data == NULL) {
            fprintf(stderr, "\nError allocating data buffer\n"); // for %s\n",data_file.c_str());
            exit(1);
        }

        ret = fread(data, sizeof(T), hdr.dim[1] * hdr.dim[2] * hdr.dim[3], fp);

        printf("ret = %ld,  size = %d\n", ret, (hdr.dim[1] * hdr.dim[2] * hdr.dim[3]));
        if (ret != hdr.dim[1] * hdr.dim[2] * hdr.dim[3]) {
            //fprintf(stderr, "\nError reading volume 1 from %s (%ld)\n",data_file.c_str(),ret);
            fprintf(stderr, "error loading volume data from file...\n");
            exit(1);
        }

        fclose(fp);

        /********** scale the data buffer  */

        /*
         if (hdr.scl_slope != 0) {
         for (i=0; i<hdr.dim[1]*hdr.dim[2]*hdr.dim[3]; i++)
         data[i] = (data[i] * hdr.scl_slope) + hdr.scl_inter;
         }
         */

        /********** print mean of data */

        total = 0;
        int max = 0;

        for (i = 0; i < hdr.dim[1] * hdr.dim[2] * hdr.dim[3]; i++) {

            total += data[i];
            if (data[i] > max) {
                // printf("%d\n", data[i]);
                max = data[i];
            }
        }
        total /= (hdr.dim[1] * hdr.dim[2] * hdr.dim[3]);
        //fprintf(stderr, "\nMean of volume 1 in %s is %.3f\n",data_file.c_str(),total);

        /** save to 3D Texture **/
        int numBytes = hdr.dim[1] * hdr.dim[2] * hdr.dim[3];
        GLubyte *oneslice = (GLubyte *) malloc(sizeof(GLubyte) * (numBytes));

        int idx = 0;
        for (i = 0; i < numBytes; i++) {
            oneslice[idx++] = (GLubyte) (((float) data[i] / (float) max) * 255);
        }

        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

        tex = Texture(oneslice, hdr.dim[1], hdr.dim[2], hdr.dim[3], GL_RGBA, GL_RED, GL_UNSIGNED_BYTE);

        tex.minFilter(GL_LINEAR);
        tex.maxFilter(GL_LINEAR);

        return (0);

    }

    static FILE *open_nifti_header(std::string data_file) {

        FILE *fp;

        /********** open and read header */
        fp = fopen(data_file.c_str(), "r");
        if (fp == NULL) {
            perror(data_file.c_str());
            fprintf(stderr, "\nError opening header file %s\n", data_file.c_str());
            exit(1);
        }
        return fp;
    }

    static nifti_1_header read_nifti_header(std::string data_file, FILE *fp) {

        unsigned long ret;
        nifti_1_header hdr;

        //read header data
        ret = fread(&hdr, MIN_HEADER_SIZE, 1, fp);
        if (ret != 1) {
            perror(data_file.c_str());
            fprintf(stderr, "\nError reading header file %s\n", data_file.c_str());
            exit(1);
        }

        //move file pointer to end of header data
        ret = fseek(fp, (long) (hdr.vox_offset), SEEK_SET);
        if (ret != 0) {
            perror(data_file.c_str());
            fprintf(stderr, "\nError doing fseek() to %ld in data file %s\n", (long) (hdr.vox_offset), data_file.c_str());
            exit(1);
        }

        return hdr;
    }

    static void print_nifti_header_info(nifti_1_header hdr) {

        /* print all header information */

//    disp_nifti_1_header( "abc", &hdr );


        /* print a little header information */

        fprintf(stderr, "\nXYZT dimensions: %d %d %d %d", hdr.dim[1], hdr.dim[2], hdr.dim[3], hdr.dim[4]);
        fprintf(stderr, "\nDatatype code and bits/pixel: %d %d", hdr.datatype, hdr.bitpix);
        fprintf(stderr, "\nScaling slope and intercept: %.6f %.6f", hdr.scl_slope, hdr.scl_inter);
        fprintf(stderr, "\nByte offset to data in datafile: %ld", (long) (hdr.vox_offset));
        fprintf(stderr, "\n");

    }

};
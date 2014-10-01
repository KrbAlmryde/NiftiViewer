//
//  NiftiData.m
//  niftiViewer
//
//  Created by Kyle Reese Almryde on 9/30/14.
//  Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#import "NiftiData.h"

using namespace std;


NiftiData::NiftiData() {} // Constructor

/*=============================
 *      load_wb1_images()     *
 =============================*/
void NiftiData::load_wb1_images(vector<NiftiImage> &images) {
    printf("in load_wb1_images\n");
//    int i = 0;
    images.clear(); images.resize(16);
    images.push_back(NiftiImage("MNI_caez_N27.nii.gz"));
    images.push_back(NiftiImage("all_s1_IC2_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s1_IC7_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s1_IC25_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s1_IC31_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s1_IC39_caez_2blur_LR.nii.gz"));

    images.push_back(NiftiImage("all_s2_IC2_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s2_IC7_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s2_IC25_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s2_IC31_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s2_IC39_caez_2blur_LR.nii.gz"));

    images.push_back(NiftiImage("all_s3_IC2_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s3_IC7_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s3_IC25_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s3_IC31_caez_2blur_LR.nii.gz"));
    images.push_back(NiftiImage("all_s3_IC39_caez_2blur_LR.nii.gz"));
}

void NiftiData::load_wb1_orig_images(vector<NiftiImage> &images){
    printf("in load_wb1_orig_images\n");
    int i = 0;
    images.clear(); images.resize(16);
    
    images[i++] = NiftiImage("MNI_2mm","nii.gz");
    
    images[i++] = NiftiImage("all_s1_IC2","nii");
    images[i++] = NiftiImage("all_s1_IC7","nii");
    images[i++] = NiftiImage("all_s1_IC25","nii");
    images[i++] = NiftiImage("all_s1_IC31","nii");
    images[i++] = NiftiImage("all_s1_IC39","nii");
    
    images[i++] = NiftiImage("all_s2_IC2","nii");
    images[i++] = NiftiImage("all_s2_IC7","nii");
    images[i++] = NiftiImage("all_s2_IC25","nii");
    images[i++] = NiftiImage("all_s2_IC31","nii");
    images[i++] = NiftiImage("all_s2_IC39","nii");
    
    images[i++] = NiftiImage("all_s3_IC2","nii");
    images[i++] = NiftiImage("all_s3_IC7","nii");
    images[i++] = NiftiImage("all_s3_IC25","nii");
    images[i++] = NiftiImage("all_s3_IC31","nii");
    images[i++] = NiftiImage("all_s3_IC39","nii");
}

void NiftiData::load_ice_images(vector<NiftiImage>& images){
    
    int i = 0;
    images.clear(); images.resize(20);
    
    images[i++] = NiftiImage("MNI_2mm","nii.gz");
    
    images[i++] = NiftiImage("IC2_s1","nii.gz");
    images[i++] = NiftiImage("IC4_s1","nii.gz");
    images[i++] = NiftiImage("IC11_s1","nii.gz");
    images[i++] = NiftiImage("IC12_s1","nii.gz");
    images[i++] = NiftiImage("IC18_s1","nii.gz");
    
    images[i++] = NiftiImage("IC2_s2","nii.gz");
    images[i++] = NiftiImage("IC4_s2","nii.gz");
    images[i++] = NiftiImage("IC11_s2","nii.gz");
    images[i++] = NiftiImage("IC12_s2","nii.gz");
    images[i++] = NiftiImage("IC18_s2","nii.gz");
    
    images[i++] = NiftiImage("IC2_s3","nii.gz");
    images[i++] = NiftiImage("IC4_s3","nii.gz");
    images[i++] = NiftiImage("IC11_s3","nii.gz");
    images[i++] = NiftiImage("IC12_s3","nii.gz");
    images[i++] = NiftiImage("IC18_s3","nii.gz");
    
    images[i++] = NiftiImage("IC2_s4","nii.gz");
    images[i++] = NiftiImage("IC4_s4","nii.gz");
    images[i++] = NiftiImage("IC11_s4","nii.gz");
    images[i++] = NiftiImage("IC12_s4","nii.gz");
    images[i++] = NiftiImage("IC18_s4","nii.gz");
}

void NiftiData::load_test_balls(vector<NiftiImage>& images){
    
    int i = 0;
    images.clear(); images.resize(10);
    
    images[i++] = NiftiImage("MNI_caez_N27","nii.gz");
    
    images[i++] = NiftiImage("ball1","nii.gz");
    images[i++] = NiftiImage("ball2","nii.gz");
    images[i++] = NiftiImage("ball3","nii.gz");
    
    images[i++] = NiftiImage("ball4","nii.gz");
    images[i++] = NiftiImage("ball5","nii.gz");
    images[i++] = NiftiImage("ball6","nii.gz");
    
    images[i++] = NiftiImage("ball7","nii.gz");
    images[i++] = NiftiImage("ball8","nii.gz");
    images[i++] = NiftiImage("ball9","nii.gz");
}


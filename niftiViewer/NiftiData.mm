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
void load_wb1_images(vector<Texture>& images){
    
    int i = 0;
    images.clear(); images.resize(16);
    
    read_nifti_file(rh.pathToResource("MNI_caez_N27","nii.gz"), images[i++]);
    //        read_nifti_file(rh.pathToResource("kyle_brain","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC2_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC7_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC25_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC31_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC39_caez_2blur_LR","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("all_s2_IC2_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC7_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC25_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC31_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC39_caez_2blur_LR","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("all_s3_IC2_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC7_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC25_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC31_caez_2blur_LR","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC39_caez_2blur_LR","nii.gz"), images[i++]);
}

void load_wb1_orig_images(vector<Texture>& images){
    
    int i = 0;
    images.clear(); images.resize(16);
    
    read_nifti_file(rh.pathToResource("MNI_2mm","nii.gz"), images[i++]);
    //        read_nifti_file(rh.pathToResource("kyle_brain","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC2","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC7","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC25","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC31","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s1_IC39","nii"), images[i++]);
    
    read_nifti_file(rh.pathToResource("all_s2_IC2","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC7","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC25","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC31","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s2_IC39","nii"), images[i++]);
    
    read_nifti_file(rh.pathToResource("all_s3_IC2","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC7","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC25","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC31","nii"), images[i++]);
    read_nifti_file(rh.pathToResource("all_s3_IC39","nii"), images[i++]);
}

void load_ice_images(vector<Texture>& images){
    
    int i = 0;
    images.clear(); images.resize(20);
    
    read_nifti_file(rh.pathToResource("MNI_2mm","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("IC2_s1","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC4_s1","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC11_s1","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC12_s1","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC18_s1","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("IC2_s2","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC4_s2","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC11_s2","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC12_s2","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC18_s2","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("IC2_s3","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC4_s3","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC11_s3","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC12_s3","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC18_s3","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("IC2_s4","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC4_s4","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC11_s4","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC12_s4","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("IC18_s4","nii.gz"), images[i++]);
}

void load_test_balls(vector<Texture>& images){
    
    int i = 0;
    images.clear(); images.resize(10);
    
    read_nifti_file(rh.pathToResource("MNI_caez_N27","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("ball1","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("ball2","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("ball3","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("ball4","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("ball5","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("ball6","nii.gz"), images[i++]);
    
    read_nifti_file(rh.pathToResource("ball7","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("ball8","nii.gz"), images[i++]);
    read_nifti_file(rh.pathToResource("ball9","nii.gz"), images[i++]);
}
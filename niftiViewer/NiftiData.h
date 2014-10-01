//
//  NiftiData.h
//  niftiViewer
//
//  Created by Kyle Reese Almryde on 9/30/14.
//  Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#ifndef niftiViewer_NiftiData_h
#define niftiViewer_NiftiData_h


#include <Aluminum/Aluminum.h>
#import "NiftiImage.h"


class NiftiData {
public:
    ResourceHandler rh;
//    vector<Texture> &tex
    NiftiData();  // Constructor, takes no arguments

    void load_wb1_images(vector<NiftiImage> &images);
    void load_wb1_orig_images(vector<NiftiImage> &images);
    void load_test_balls(vector<NiftiImage>& images);
    void load_ice_images(vector<NiftiImage>& images);
};

#endif

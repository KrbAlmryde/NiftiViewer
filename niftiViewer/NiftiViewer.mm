//
//  NiftiViewer.mm
//  niftiViewer
//
//  Created by Kyle Almryde on 7/25/14.
//  Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#include <Aluminum/Aluminum.h>
#include "nifti1_io.h"
#include "NiftiData.h"
//#include "ActionProxy.h"

using namespace std;
using namespace glm;
using namespace aluminum;

class NiftiViewer: public RendererOSX {
public:
/*
    // MNI_caez_N27
    const static int XDIM = 151;//176
    const static int YDIM = 188;//240;
    const static int ZDIM = 154;//256;
*/

    // MNI_2mm.nii
    const static int XDIM = 91;//176
    const static int YDIM = 109;//240;
    const static int ZDIM = 91;//256;

    NiftiData nd;
    
    // Setup Aluminum specific stuff
    vector<Texture> images;
    Camera camera;
    ResourceHandler rh;
    MeshBuffer cubeMB, lCubeMB, rCubeMB, axisMB;
    vector <MeshBuffer> mbSlice;
    FBO fboA, fboB, fboColor;
    Program wb1Shader, axisShader, wireShader;
    Program blendShader, brainShader, clustShader;

    // Stereographic control
    bool USE_STEREO = false;

    // Shader input variables
    float iso = 80.0;
    float DELTA = 0.01;
    float mdDim = 0.5;
    float timePerc = 0.0;
    float brainOpacity = 1.0;


    // Setup our Matrices
    float tX, tY, tZ = 0.0;
    float rX, rY, rZ = 0.0;

    mat4 model, view, proj, mvp;
    mat4 Rx, Ry, Rz, Tr;
    mat4 M, MV, VP, MVP;


    vec3 camPos;
    // Vertex Array and Buffer Ids
    GLuint vaoX, vaoY, vaoZ;
    GLuint vboX, vboY, vboZ;


    vec4 clusterColors[6] = {
//        vec4(0.00, 0.00, 1.0, 1.0),  // Blue
        vec4(0.50, 0.50, 0.5, 1.0),  // grey-Brain
        vec4(1.00, 0.00, 0.0, 1.0),  // Red
        vec4(1.00, 1.00, 0.0, 1.0),  // Yellow
        vec4(1.00, 0.55, 0.0, 1.0),  // Orange
        vec4(0.00, 1.00, 0.0, 1.0),  // Green
        vec4(0.50, 0.00, 1.0, 1.0),  // Purple
    };

    /*=============================
     *        onCreate()          *
     =============================*/
    virtual void onCreate() {

        initFBOs();
        nd.load_wb1_orig_images(images);
        
        printf("\nloading shaders now\n");
        rh.loadProgram(brainShader, "brain", 0, -1, -1, -1);
        rh.loadProgram(clustShader, "cluster", 0, -1, -1, -1);
        rh.loadProgram(blendShader, "blend", 0, -1, -1, -1);

        rh.loadProgram(wb1Shader, "wb1", 0, -1, -1, -1);
        rh.loadProgram(axisShader, "axis", 0, -1, -1, 1);
        rh.loadProgram(wireShader, "wire", 0, -1, 1, -1);
        // Setup camera
        camera = Camera(radians(60.0),
                        (float) width / height,
                        0.01,
                        100.0).translateZ(-2); // .convergence(10.0).eyeSep(1.0 / 30.0 * 10.0);

        // Setup our ray cube
        axisMB.init(makeAxis(1.0), 0, -1, -1, 1);
        cubeMB.init(MeshUtils::makeCube(mdDim), 0, -1, -1, -1);
        lCubeMB.init(makeThinCube(mdDim, 0.0), 0, -1, -1, -1);
        rCubeMB.init(makeThinCube(-mdDim, 0.0), 0, -1, -1, -1);

    }


    /*=============================
     *        onFrame()           *
     =============================*/
    virtual void onFrame() {
        handleMouse();
        handleKeys();

        if (camera.isTransformed) {
            camera.transform();
        }
        //set the model transform
        Rx = rotate(radians(rX), vec3(1.0,0.,0.));
        Ry = rotate(radians(rY), vec3(0.,1.0,0.));
        Rz = rotate(radians(rZ), vec3(0.,0.,1.));
        M = Rx * Ry * Rz;
        MV = camera.view * M;
        VP = camera.projection * camera.view;
        MVP = VP * M;

        //get the camera position
        camPos = glm::vec3(glm::inverse(MV) * glm::vec4(0, 0, 0, 1));

        glScissor(0, 0, width, height);
        glViewport(0, 0, (GLsizei) width, (GLsizei) height);

        glClearColor(0.0, 0.0, 0.0, 0.0);

        glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);

        //enable blending and bind the cube vertex array object
        glEnable(GL_BLEND);

        //enable depth test
        glEnable(GL_DEPTH_TEST);
//        glEnable(GL_SCISSOR_TEST);

        //set the over blending function
        glDepthFunc(GL_LEQUAL);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);  //glBlendFunc(GL_ZERO, GL_SRC_COLOR); //glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

//       drawBrain(brainShader);
//       drawCluster(clustShader);
//       drawNii(blendShader);

        drawNiftiView(wb1Shader);
//        drawAxis(axisShader, vec4(1.0));
//        drawFrame(wireShader);
        // drawTestBalls(wb1Shader);
    }


    /*=============================
     *        onReshape()         *
     =============================*/
    virtual void onReshape() {

        glViewport(0, 0, (GLsizei) width, (GLsizei) height);
        camera = Camera(60.0, (float) width / height, 0.001, 100.0).translateZ(-2);

//        if (USE_STEREO)
//            camera.perspective(60.0, (float) width / height, 0.001, 100.0).stereo(USE_STEREO);
//        else {
//            camera = Camera(60.0, (float) width / height, 0.001, 100.0).translate(camera.posVec);
//            camera.perspective(60.0, (float) width / height, 0.001, 100.0).stereo(USE_STEREO);
//        }

//        proj = camera.projection;

    }
    
    void load_wb1_images(){
        
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

    /*=============================
     *          intiFBO()         *
     =============================*/
    void initFBOs() {
        fboA.create(XDIM, YDIM);
        fboA.texture.wrapMode(GL_CLAMP_TO_EDGE);
        fboA.texture.minFilter(GL_LINEAR);
        fboA.texture.maxFilter(GL_LINEAR);

        fboB.create(XDIM, YDIM);
        fboB.texture.wrapMode(GL_CLAMP_TO_EDGE);
        fboB.texture.minFilter(GL_LINEAR);
        fboB.texture.maxFilter(GL_LINEAR);
    }


    /*=============================
     *      read_nifti_file()     *
     =============================*/
    static int read_nifti_file(string fname, Texture &tex) {

        nifti_image * nim = nifti_image_read(fname.c_str(), 1);
        znzFile fp = znzopen(nim->iname, "rb", nifti_is_gzfile(nim->iname));

        if (nim == NULL)
            exit(1);

        nifti_image_infodump(nim);

        /** save to 3D Texture **/
        switch (nim->datatype) {
            case 2:
                load_nifti_texture<unsigned char>(fp, nim, tex);
                break;
            case 4:
                load_nifti_texture<signed short>(fp, nim, tex);
                break;
            case 8:
                load_nifti_texture<signed int>(fp, nim, tex);
                break;
            case 16:
                load_nifti_texture<float>(fp, nim, tex);
                break;
            case 64:
                load_nifti_texture<double>(fp, nim, tex);
                break;
            default :
                printf("data type %d is not supported... exiting...\n", nim->datatype);
                exit(1);
        }

        return 0;
    }

    /*=============================
     *          drawNii()         *
     =============================*/
    void drawNii(Program shader){
        shader.bind();
        {
            //pass shader uniforms
            glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP));  // Used in Vertex Shader
            glUniform1i(shader.uniform("vVol0"), 0);
            glUniform1i(shader.uniform("vVol1"), 1);

            //render the cube
            fboA.texture.bind(GL_TEXTURE0);
            fboB.texture.bind(GL_TEXTURE1);
                cubeMB.draw();
            fboA.texture.unbind(GL_TEXTURE0);
            fboB.texture.unbind(GL_TEXTURE1);
        }
        shader.unbind();
    }

    /*=============================
     *         drawBrain()        *
     =============================*/
    void drawBrain(Program shader){
        shader.bind();
        {
            //pass shader uniforms
            glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP));  // Used in Vertex Shader
            glUniform3fv(shader.uniform("camPos"),  1, glm::value_ptr(camPos));
            glUniform3f(shader.uniform("step_size"), 1.0f/XDIM, 1.0f/YDIM, 1.0f/ZDIM);
            glUniform1f(shader.uniform("brainOpacity"), brainOpacity);
            glUniform1f(shader.uniform("iso"), iso);
            glUniform1f(shader.uniform("DELTA"), DELTA);
            glUniform1i(shader.uniform("MAX_SAMPLES"), 300);

            glUniform4fv(shader.uniform("vColor0"), 1, glm::value_ptr(clusterColors[0]));
            glUniform1i(shader.uniform("vVol0"), 0);

            //render the cube
            fboA.bind();
            {
                images[0].bind(GL_TEXTURE0);
                    cubeMB.draw();
                images[0].unbind(GL_TEXTURE0);
            }
            fboA.unbind();
        }
        shader.unbind();
    }

    /*=============================
     *       drawCluster()        *
     =============================*/
    void drawCluster(Program shader){
        float tpx2 = (timePerc * 2.0);
        float tpm5x2 = ((timePerc - 0.5) * 2.0);

        shader.bind();
        {
            //pass shader uniforms
            glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP));  // Used in Vertex Shader
            glUniform3fv(shader.uniform("camPos"),  1, glm::value_ptr(camPos));
            glUniform3f(shader.uniform("step_size"), 1.0f/XDIM, 1.0f/YDIM, 1.0f/ZDIM);
            glUniform1f(shader.uniform("brainOpacity"), brainOpacity);

            glUniform1f(shader.uniform("timePerc"), timePerc);
            glUniform1f(shader.uniform("tpx2"), tpx2);
            glUniform1f(shader.uniform("tpm5x2"), tpm5x2);
            glUniform1f(shader.uniform("iso"), iso);
            glUniform1f(shader.uniform("DELTA"), DELTA);
            glUniform1i(shader.uniform("MAX_SAMPLES"), 300);

            glUniform4fv(shader.uniform("vColor1"), 1, glm::value_ptr(clusterColors[1]));
            glUniform4fv(shader.uniform("vColor2"), 1, glm::value_ptr(clusterColors[2]));
            glUniform4fv(shader.uniform("vColor3"), 1, glm::value_ptr(clusterColors[3]));
            glUniform4fv(shader.uniform("vColor4"), 1, glm::value_ptr(clusterColors[4]));
            glUniform4fv(shader.uniform("vColor5"), 1, glm::value_ptr(clusterColors[5]));

            glUniform1i(shader.uniform("vVol1A"), 0);
            glUniform1i(shader.uniform("vVol2A"), 1);
            glUniform1i(shader.uniform("vVol3A"), 2);
            glUniform1i(shader.uniform("vVol4A"), 3);
            glUniform1i(shader.uniform("vVol5A"), 4);

            glUniform1i(shader.uniform("vVol1B"), 5);
            glUniform1i(shader.uniform("vVol2B"), 6);
            glUniform1i(shader.uniform("vVol3B"), 7);
            glUniform1i(shader.uniform("vVol4B"), 8);
            glUniform1i(shader.uniform("vVol5B"), 9);

            //render the cube
            if (timePerc < 0.5) {
                // printf("timePerc: %f < 0.5! %f \n",timePerc, (timePerc * 2.0));
                fboB.bind();
                {
                    for (int i = 0; i < 10; i++) { images[i].bind(GL_TEXTURE0+i); }

                        cubeMB.draw();

                    for (int i = 0; i < 10; i++) { images[i].unbind(GL_TEXTURE0+i); }
                }
                fboB.unbind();

            } else {
                // printf("timePerc: %f >= 0.5! %f \n", timePerc, ((timePerc - 0.5) * 2.0));

                fboB.bind();
                {
                    for (int i = 5; i < 10; i++) { images[i].bind(GL_TEXTURE0+i); }

                        cubeMB.draw();

                    for (int i = 5; i < 10; i++) { images[i].unbind(GL_TEXTURE0+i); }
                }
                fboB.unbind();
            }
            //unbind the raycasting shader
        }
        shader.unbind();
    }

    /*=============================
     *       drawNiftiView()      *
     =============================*/
    void drawNiftiView(Program shader){
        float tpx2 = (timePerc * 2.0);
        float tpm5x2 = ((timePerc - 0.5) * 2.0);

        shader.bind();
        {
            //pass shader uniforms
            glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP));  // Used in Vertex Shader
            glUniform3fv(shader.uniform("camPos"),  1, glm::value_ptr(camPos));
            glUniform3f(shader.uniform("step_size"), 1.0f/XDIM, 1.0f/YDIM, 1.0f/ZDIM);
            glUniform1f(shader.uniform("brainOpacity"), brainOpacity);

            glUniform1f(shader.uniform("timePerc"), timePerc);
            glUniform1f(shader.uniform("tpx2"), tpx2);
            glUniform1f(shader.uniform("tpm5x2"), tpm5x2);
            glUniform1f(shader.uniform("iso"), iso);
            glUniform1f(shader.uniform("DELTA"), DELTA);
            glUniform1i(shader.uniform("MAX_SAMPLES"), 300);

            glUniform4fv(shader.uniform("vColor0"), 1, glm::value_ptr(clusterColors[0]));
            glUniform4fv(shader.uniform("vColor1"), 1, glm::value_ptr(clusterColors[1]));
            glUniform4fv(shader.uniform("vColor2"), 1, glm::value_ptr(clusterColors[2]));
            glUniform4fv(shader.uniform("vColor3"), 1, glm::value_ptr(clusterColors[3]));
            glUniform4fv(shader.uniform("vColor4"), 1, glm::value_ptr(clusterColors[4]));
            glUniform4fv(shader.uniform("vColor5"), 1, glm::value_ptr(clusterColors[5]));

            glUniform1i(shader.uniform("vVol0"), 0);
            glUniform1i(shader.uniform("vVol1A"), 1);
            glUniform1i(shader.uniform("vVol2A"), 2);
            glUniform1i(shader.uniform("vVol3A"), 3);
            glUniform1i(shader.uniform("vVol4A"), 4);
            glUniform1i(shader.uniform("vVol5A"), 5);

            glUniform1i(shader.uniform("vVol1B"), 6);
            glUniform1i(shader.uniform("vVol2B"), 7);
            glUniform1i(shader.uniform("vVol3B"), 8);
            glUniform1i(shader.uniform("vVol4B"), 9);
            glUniform1i(shader.uniform("vVol5B"), 10);

            //render the cube
            if (timePerc < 0.5) {
                // printf("timePerc: %f < 0.5! %f \n",timePerc, (timePerc * 2.0));

                for (int i = 0; i < 11; i++) { images[i].bind(GL_TEXTURE0+i); }

                    cubeMB.draw();

                for (int i = 0; i < 11; i++) { images[i].unbind(GL_TEXTURE0+i); }

            } else {
                // printf("timePerc: %f >= 0.5! %f \n", timePerc, ((timePerc - 0.5) * 2.0));

                images[0].bind(GL_TEXTURE0);
                for (int i = 1; i < 11; i++) { images[i+5].bind(GL_TEXTURE0+i); }

                    cubeMB.draw();


                images[0].unbind(GL_TEXTURE0);
                for (int i = 1; i < 11; i++) { images[i+5].unbind(GL_TEXTURE0+i); }

            }
            //unbind the raycasting shader
        }
        shader.unbind();
    }

    /*=============================
     *       drawTestBalls()      *
     =============================*/
    void drawTestBalls(Program shader){
        float tpx2 = (timePerc * 2.0);
        float tpm5x2 = ((timePerc - 0.5) * 2.0);

        shader.bind();
        {
            //pass shader uniforms
            glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP));  // Used in Vertex Shader
            glUniform3fv(shader.uniform("camPos"),  1, glm::value_ptr(camPos));
            glUniform3f(shader.uniform("step_size"), 1.0f/XDIM, 1.0f/YDIM, 1.0f/ZDIM);
            glUniform1f(shader.uniform("brainOpacity"), brainOpacity);

            glUniform1f(shader.uniform("timePerc"), timePerc);
            glUniform1f(shader.uniform("tpx2"), tpx2);
            glUniform1f(shader.uniform("tpm5x2"), tpm5x2);
            glUniform1i(shader.uniform("MAX_SAMPLES"), 300);

            glUniform4fv(shader.uniform("vColor0"), 1, glm::value_ptr(clusterColors[1]));
            glUniform4fv(shader.uniform("vColor1"), 1, glm::value_ptr(clusterColors[1]));
            glUniform4fv(shader.uniform("vColor2"), 1, glm::value_ptr(clusterColors[2]));
            glUniform4fv(shader.uniform("vColor3"), 1, glm::value_ptr(clusterColors[3]));
            glUniform4fv(shader.uniform("vColor4"), 1, glm::value_ptr(clusterColors[4]));
            glUniform4fv(shader.uniform("vColor5"), 1, glm::value_ptr(clusterColors[5]));

            glUniform1i(shader.uniform("vVol0"), 0);
            glUniform1i(shader.uniform("vVol1A"), 1);
            glUniform1i(shader.uniform("vVol2A"), 2);
            glUniform1i(shader.uniform("vVol3A"), 3);
            glUniform1i(shader.uniform("vVol4A"), 4);
            glUniform1i(shader.uniform("vVol5A"), 5);

            glUniform1i(shader.uniform("vVol1B"), 6);
            glUniform1i(shader.uniform("vVol2B"), 7);
            glUniform1i(shader.uniform("vVol3B"), 8);
            glUniform1i(shader.uniform("vVol4B"), 9);
            glUniform1i(shader.uniform("vVol5B"), 10);

            //render the cube
            if (timePerc < 0.5) {
                // printf("timePerc: %f < 0.5! %f \n",timePerc, (timePerc * 2.0));

               for (int i = 0; i < 10; i++) { images[i].bind(GL_TEXTURE0+i); }

                    cubeMB.draw();

               for (int i = 0; i < 10; i++) { images[i].unbind(GL_TEXTURE0+i); }

            } else {
                // printf("timePerc: %f >= 0.5! %f \n", timePerc, ((timePerc - 0.5) * 2.0));

                images[0].bind(GL_TEXTURE0);
                for (int i = 1; i < 10; i++) { images[i+5].bind(GL_TEXTURE0+i); }

                    cubeMB.draw();

                images[0].unbind(GL_TEXTURE0);
                for (int i = 1; i < 10; i++) { images[i+5].unbind(GL_TEXTURE0+i); }
            }
            //unbind the raycasting shader
        }
        shader.unbind();
    }


    /*=============================
     *        handleKeys()       *
     =============================*/
    virtual void handleKeys() {
        if (keysDown[kVK_Space]){
            keysDown[kVK_Space] = false;
            rX = 0; tX = 0;
            rY = 0; tY = 0;
            rZ = 0; tZ = 0;
            debugInfo();
            camera.printCameraInfo();
        }
        // Adjust Brain Opacity -
        if (keysDown[kVK_ANSI_LeftBracket]) {
            keysDown[kVK_ANSI_LeftBracket] = false;
            if (brainOpacity > 0.0) {
                brainOpacity -= 0.01;
            } else {
                brainOpacity = 0.0;
            }
            cout << "bO = " << brainOpacity << endl;
        }

        // Adjust Brain Opacity +
        if (keysDown[kVK_ANSI_RightBracket]) {
            keysDown[kVK_ANSI_RightBracket] = false;
            if (brainOpacity < 1.0) {
                brainOpacity += 0.01;
            } else {
                brainOpacity = 1.0;
            }
            cout << "bO = " << brainOpacity << endl;
        }

        // Adjust Time Perc -
        if (keysDown[kVK_ANSI_Comma]) {
            keysDown[kVK_ANSI_Comma] = false;
            if (timePerc > 0.0) {
                timePerc -= 0.01;
            } else {
                timePerc = 0.0;
            }
            cout << "timePerc = " << timePerc << endl;
        }

        // Adjust Time Perc +
        if (keysDown[kVK_ANSI_Period]) {
            keysDown[kVK_ANSI_Period] = false;
            if (timePerc < 1.0) {
                timePerc += 0.01;
            } else {
                timePerc = 1.0;
            }
            cout << "timePerc = " << timePerc << endl;
        }

        if (keysDown[kVK_ANSI_W]) {
            keysDown[kVK_ANSI_W] = false;
            rX -= 1.0; // Up
            camera.printCameraInfo();
            debugInfo();
        }
        if (keysDown[kVK_ANSI_S]) {
            keysDown[kVK_ANSI_S] = false;
            rX += 1.0; // Up
            camera.printCameraInfo();
            debugInfo();
        } // down

        if (keysDown[kVK_ANSI_A]) {
            keysDown[kVK_ANSI_A] = false;
            rZ -= 1.0; // Rotate right
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_D]) {
            keysDown[kVK_ANSI_D] = false;
            rZ += 1.0; // Rotate left
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_E]) {
            keysDown[kVK_ANSI_E] = false;
            rY -= 1.0; // left
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Q]) {
            keysDown[kVK_ANSI_Q] = false;
            rY += 1.0; // right
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Z]) {
            keysDown[kVK_ANSI_Z] = false;
            camera.translateZ(0.01);   // + Zoom
            camera.printCameraInfo();
            debugInfo();
            printf("translate CameraZ, Z key!!");
        }
        if (keysDown[kVK_ANSI_X]) {
            keysDown[kVK_ANSI_X] = false;
            camera.translateZ(-0.01);  // - Zoom
            camera.printCameraInfo();
            debugInfo();
            printf("translate CameraX, X key!!");
        }


        if (keysDown[kVK_ANSI_I]) {
            keysDown[kVK_ANSI_I] = false;
            camera.translateX(-0.01);; // Up
            camera.printCameraInfo();
            debugInfo();
        }
        if (keysDown[kVK_ANSI_K]) {
            keysDown[kVK_ANSI_K] = false;
            camera.translateX(0.01); // Up
            camera.printCameraInfo();
            debugInfo();
        } // down

        if (keysDown[kVK_ANSI_J]) {
            keysDown[kVK_ANSI_J] = false;
            camera.translate(vec3(-0.01)); // Rotate right
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_L]) {
            keysDown[kVK_ANSI_L] = false;
            camera.translate(vec3(0.01)); // Rotate left
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_U]) {
            keysDown[kVK_ANSI_U] = false;
            camera.translateY(-0.01); // left
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_O]) {
            keysDown[kVK_ANSI_O] = false;
            camera.translateY(0.01); // right
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Keypad4]) {
            keysDown[kVK_ANSI_Keypad4] = false;
            DELTA += 0.01;
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Keypad1]) {
            keysDown[kVK_ANSI_Keypad1] = false;
            DELTA -= 0.01;
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Keypad6]) {
            keysDown[kVK_ANSI_Keypad6] = false;
            iso += 1.0;
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Keypad3]) {
            keysDown[kVK_ANSI_Keypad3] = false;
            iso -= 1.0;
            debugInfo();
        }


        if (keysDown[kVK_ANSI_KeypadPlus]) {
            keysDown[kVK_ANSI_KeypadPlus] = false;
            mdDim+=0.001;
            cubeMB.update(MeshUtils::makeCube(mdDim));
            lCubeMB.update(makeThinCube(mdDim,0.0));
            rCubeMB.update(makeThinCube(-mdDim,0.0));
            debugInfo();
        }

        if (keysDown[kVK_ANSI_KeypadMinus]) {
            keysDown[kVK_ANSI_KeypadMinus] = false;
            mdDim-=0.001;
            cubeMB.update(MeshUtils::makeCube(mdDim));
            lCubeMB.update(makeThinCube(mdDim,0.0));
            rCubeMB.update(makeThinCube(-mdDim,0.0));
            debugInfo();
        }


        if (keysDown[kVK_ANSI_0]) {
            keysDown[kVK_ANSI_0] = false;
            if (clusterColors[0].a == 0.0)
                clusterColors[0].a = 1.0;
            else
                clusterColors[0].a = 0.0;
            printf("clusterColors[0].a = %f\n",clusterColors[0].a);
        }

        if (keysDown[kVK_ANSI_1]) {
            keysDown[kVK_ANSI_1] = false;
            if (clusterColors[1].a == 0.0)
                clusterColors[1].a = 1.0;
            else
                clusterColors[1].a = 0.0;
            printf("clusterColors[1].a = %f\n",clusterColors[1].a);
        }

        if (keysDown[kVK_ANSI_2]) {
            keysDown[kVK_ANSI_2] = false;
            if (clusterColors[2].a == 0.0)
                clusterColors[2].a = 1.0;
            else
                clusterColors[2].a = 0.0;
            printf("clusterColors[2].a = %f\n",clusterColors[2].a);
        }

        if (keysDown[kVK_ANSI_3]) {
            keysDown[kVK_ANSI_3] = false;
            if (clusterColors[3].a == 0.0)
                clusterColors[3].a = 1.0;
            else
                clusterColors[3].a = 0.0;
            printf("clusterColors[3].a = %f\n",clusterColors[3].a);
        }

        if (keysDown[kVK_ANSI_4]) {
            keysDown[kVK_ANSI_4] = false;
            if (clusterColors[4].a == 0.0)
                clusterColors[4].a = 1.0;
            else
                clusterColors[4].a = 0.0;
            printf("clusterColors[4].a = %f\n",clusterColors[4].a);
        }

        if (keysDown[kVK_ANSI_5]) {
            keysDown[kVK_ANSI_5] = false;
            if (clusterColors[5].a == 0.0)
                clusterColors[5].a = 1.0;
            else
                clusterColors[5].a = 0.0;
            printf("clusterColors[5].a = %f\n",clusterColors[5].a);
        }
    }

    /*=============================
     *        handleMouse()       *
     =============================*/
    virtual void handleMouse() {
        bool movingLeft = false;
        bool movingRight = false;
        bool movingUp = false;
        bool movingDown = false;

        if (abs(mouseX - previousMouseX) > abs(mouseY - previousMouseY)) {
            if (mouseX < previousMouseX) movingLeft = true;
            else movingRight = true;
        } else {
            if (mouseY < previousMouseY) movingUp = true;
            else movingDown = true;

        }
        if (isDragging) {
            rX += 0.5;
            rY += 0.5;
            rZ += 0.5;


            if (movingLeft)
                rZ -= 2.0;
            else if (movingRight)
                rZ += 2.0;


            if (movingUp)
                rX += 2.0;
            else if (movingDown)
                rX -= 2.0;

            rX -= 0.5;
            rY -= 0.5;
            rZ -= 0.5;
        }

        if (isMoving)
            isMoving = !isMoving; //isn't a listener that can hear when a mouse *stops*?

    }


protected:
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


    /*-----------------------------
     *        drawFrame()         *
     -----------------------------*/
    void drawFrame(Program shader) {
        // printf("\n\tIn draw!\n");

        shader.bind();
        {

            glUniformMatrix4fv(shader.uniform("MVP"), 1, 0, value_ptr(MVP));
            glUniformMatrix4fv(shader.uniform("M"), 1, 0, ptr(M));
            cubeMB.drawLines();

        }
        shader.unbind();
    } // end of void draw()

    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
    void drawAxis(Program shader, vec4 color){
        shader.bind();
        {
            glUniformMatrix4fv(shader.uniform("model"), 1, 0, value_ptr(MVP));
            glUniform4fv(shader.uniform("g_color"), 1, value_ptr(color));

            axisMB.drawLines();
        }
        shader.unbind();
    }

    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
    MeshData makeAxis(float s){
        MeshData md;
        const vec3 vs[] = {
            vec3(-s,0.0,0.0), vec3(s,0.0,0.0),
            vec3(0.0,-s,0.0), vec3(0.0,s,0.0),
            vec3(0.0,0.0,-s), vec3(0.0,0.0,s)
        };

        const vec3 cs[] = {
            vec3(1.0,0.0,0.0), vec3(1.0,0.0,0.0),
            vec3(0.0,1.0,0.0), vec3(0.0,1.0,0.0),
            vec3(0.0,0.0,1.0), vec3(0.0,0.0,1.0)

        };
        const unsigned int indicies[] = {
            0, 1,
            2, 3,
            4, 5
        };

        md.vertex(vs, 6);
        md.index(indicies, 6);
        md.color(cs, 6);
        return md;
    }


    /*
     These two functions were taken from this thread via Stack Overflow, very helpful!
     http://stackoverflow.com/questions/236129/how-to-split-a-string-in-c
     */

    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
   std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
        std::stringstream ss(s);
        std::string item;
        while (std::getline(ss, item, delim)) {
            elems.push_back(item);
        }
        return elems;
    }

    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
    std::vector<std::string> split(const std::string &s, char delim) {
        std::vector<std::string> elems;
        split(s, delim, elems);
        return elems;
    }


    /*
     And this thread helped with this function...
     http://stackoverflow.com/questions/9277906/stdvector-to-string-with-custom-delimiter
     */
    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
    std::string join(const vector<std::string> vec, const std::string delim="."){
        stringstream s;
        copy(vec.begin(),vec.end(),std::ostream_iterator<std::string>(s,delim.c_str()));
        std::string result = s.str();
        result.pop_back();
        return result;
    }


    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
    MeshData makeThinCube(float s, float w) {

        MeshData m;

        //8 vertices
        vec3 v0 = vec3(-s,-s,s);
        vec3 v1 = vec3(-s,s,s);
        vec3 v2 = vec3(w,-s,s);
        vec3 v3 = vec3(w,s,s);
        vec3 v4 = vec3(-s,-s,-s);
        vec3 v5 = vec3(-s,s,-s);
        vec3 v6 = vec3(w,-s,-s);
        vec3 v7 = vec3(w,s,-s);

        //6 sides
        vec3 n0 = vec3(0,0,s);
        vec3 n1 = vec3(0,0,-s);
        vec3 n2 = vec3(0,s,0);
        vec3 n3 = vec3(0,-s,0);
        vec3 n4 = vec3(s,0,0);
        vec3 n5 = vec3(-s,0,0);

        //4 texcoords
        vec3 t0 = vec3(0,0,0);
        vec3 t1 = vec3(0,1,0);
        vec3 t2 = vec3(1,0,0);
        vec3 t3 = vec3(1,1,0);

        const vec3 vs[] = {
                v2, v3, v6, v7, //right
                v4, v5, v0, v1, //left
                v0, v1, v2, v3, //front
                v4, v5, v6, v7, //back
                v1, v5, v3, v7, //top
                v0, v4, v2, v6  //bottom
        };

        const vec3 ns[] = {
                n4, n4, n4, n4,
                n5, n5, n5, n5,
                n0, n0, n0, n0,
                n1, n1, n1, n1,
                n2, n2, n2, n2,
                n3, n3, n3, n3
        };

        const vec3 ts[] = {
                t0, t1, t2, t3,
                t0, t1, t2, t3,
                t0, t1, t2, t3,
                t0, t1, t2, t3,
                t0, t1, t2, t3,
                t0, t1, t2, t3
        };

        const unsigned int indices[] = {
                0,1,2, 2,1,3,
                4,5,6, 6,5,7,
                8,9,10, 10,9,11,
                12,13,14, 14,13,15,
                16,17,18, 18,17,19,
                20,21,22, 22,21,23
        };

        m.vertex(vs, 24);
        m.normal(ns, 24);
        m.texCoord(ts, 24);
        m.index(indices, 36);

        return m;
    }


    /*-----------------------------
     *         drawAxis()         *
     -----------------------------*/
    void debugInfo() {

        printf("\n========================= Local ===========================\n");

        printf("\t        Rx: %f, %f, %f, %f \n", Rx[0].x, Rx[0].y, Rx[0].z, Rx[0].a);
        printf("\t            %f, %f, %f, %f \n", Rx[1].x, Rx[1].y, Rx[1].z, Rx[1].a);
        printf("\t            %f, %f, %f, %f \n", Rx[2].x, Rx[2].y, Rx[2].z, Rx[2].a);
        printf("\t            %f, %f, %f, %f \n\n", Rx[3].x, Rx[3].y, Rx[3].z, Rx[3].a);

        printf("\t        Ry: %f, %f, %f, %f \n", Ry[0].x, Ry[0].y, Ry[0].z, Ry[0].a);
        printf("\t            %f, %f, %f, %f \n", Ry[1].x, Ry[1].y, Ry[1].z, Ry[1].a);
        printf("\t            %f, %f, %f, %f \n", Ry[2].x, Ry[2].y, Ry[2].z, Ry[2].a);
        printf("\t            %f, %f, %f, %f \n\n", Ry[3].x, Ry[3].y, Ry[3].z, Ry[3].a);

        printf("\t         M: %f, %f, %f, %f \n", M[0].x, M[0].y, M[0].z, M[0].a);
        printf("\t            %f, %f, %f, %f \n", M[1].x, M[1].y, M[1].z, M[1].a);
        printf("\t            %f, %f, %f, %f \n", M[2].x, M[2].y, M[2].z, M[2].a);
        printf("\t            %f, %f, %f, %f \n\n", M[3].x, M[3].y, M[3].z, M[3].a);

        printf("\t        MV: %f, %f, %f, %f \n", MV[0].x, MV[0].y, MV[0].z, MV[0].a);
        printf("\t            %f, %f, %f, %f \n", MV[1].x, MV[1].y, MV[1].z, MV[1].a);
        printf("\t            %f, %f, %f, %f \n", MV[2].x, MV[2].y, MV[2].z, MV[2].a);
        printf("\t            %f, %f, %f, %f \n\n", MV[3].x, MV[3].y, MV[3].z, MV[3].a);

        printf("\t       MVP: %f, %f, %f, %f \n", MVP[0].x, MVP[0].y, MVP[0].z, MVP[0].a);
        printf("\t            %f, %f, %f, %f \n", MVP[1].x, MVP[1].y, MVP[1].z, MVP[1].a);
        printf("\t            %f, %f, %f, %f \n", MVP[2].x, MVP[2].y, MVP[2].z, MVP[2].a);
        printf("\t            %f, %f, %f, %f \n\n", MVP[3].x, MVP[3].y, MVP[3].z, MVP[3].a);

        printf("\t    camPos: %f, %f, %f \n\n", camPos.x, camPos.y, camPos.z);

        printf("\t            rX: %f\ttX: %f\n", rX,tX);
        printf("\t            rY: %f\ttY: %f\n", rY,tY);
        printf("\t            rZ: %f\ttZ: %f\n\n", rZ,tZ);
        printf("\t            mdDim: %f\tiso: %f\tDELTA: %f\n",mdDim, iso, DELTA);
        printf("\t            timePerc: %f\tbrainOpacity: %f\n", timePerc, brainOpacity);

    }
};

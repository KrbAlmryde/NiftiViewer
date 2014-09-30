//
//#import "Includes.hpp"
//
//#import "MeshBuffer.hpp"
//#import "MeshUtils.hpp"
//#import "Program.hpp"
//#import "Shapes.hpp"
//#import "Camera.hpp"

#import "NiftiUtils.h"
#import "ActionProxy.h"

#define BUFFER_OFFSET(i) (reinterpret_cast<void*>(i))

using namespace aluminum;

class Slices : public RendererOSX {

public:

    // Set Global vars
    bool USE_STEREO = false;
    string RESOURCES = (string) [NSHomeDirectory() UTF8String] + "/Dropbox/XCodeProjects/aluminum/osx/examples/niftiViewer-KrbA/resources/";
    int numSlices = 100;

    Camera camera;

    vector<MeshBuffer> mbs;

    mat4 textureRotation, textureRotationStart, view, proj;

    Program program;

    GLint posLoc = 0;
    GLint texCoordLoc = 1;

    Texture brain;
    Texture cluster1_time1, cluster1_time2, cluster1_time3;
    Texture cluster2_time1, cluster2_time2, cluster2_time3;
    Texture cluster3_time1, cluster3_time2, cluster3_time3;
    Texture cluster4_time1, cluster4_time2, cluster4_time3;
    Texture cluster5_time1, cluster5_time2, cluster5_time3;

    MeshBuffer mb1;

    float bloomAmt = 0.1;
    float orbitRadius = 1.0;
    float opacity = 0.1;
    float percent = 0.0;
    float cameraZ = 5.0;  // 0.95

    bool rotateTextureX_plus = false;
    bool rotateTextureX_minus = false;

    NSSlider *opacitySlider;
    NSSlider *percentSlider;
    NSDrawer *drawerLeftSide;
    NSDrawer *drawerRightSide;
    NSDrawer *drawerBottomSide;
    NSDrawer *drawerTopSide;

    int useCluster1 = 0;
    int useCluster2 = 0;
    int useCluster3 = 0;
    int useCluster4 = 0;
    int useCluster5 = 0;
    int whichClusters = 0;

    // wrapper for Texture::loadTexture
    void loadTexture(Texture &t, const std::string &name) {
        t.loadTexture(t, name);
    } // end of loadTexture


    /*******************************************************************
     *  Using the supplied path, creates a string of the nifti file to
     *  be loaded into a texture
     *
     *  Loads a nifti file into a 3D Texture
     */

    void loadNiftiInto3DTextures(string path) {
        string nii_brain = (path + "MNI_2mm.nii").c_str();
        string nii_c1t1 = (path + "all_s1_IC2.nii").c_str();
        string nii_c1t2 = (path + "all_s2_IC2.nii").c_str();
        string nii_c1t3 = (path + "all_s3_IC2.nii").c_str();
        string nii_c2t1 = (path + "all_s1_IC7.nii").c_str();
        string nii_c2t2 = (path + "all_s2_IC7.nii").c_str();
        string nii_c2t3 = (path + "all_s3_IC7.nii").c_str();
        string nii_c3t1 = (path + "all_s1_IC25.nii").c_str();
        string nii_c3t2 = (path + "all_s2_IC25.nii").c_str();
        string nii_c3t3 = (path + "all_s3_IC25.nii").c_str();
        string nii_c4t1 = (path + "all_s1_IC31.nii").c_str();
        string nii_c4t2 = (path + "all_s2_IC31.nii").c_str();
        string nii_c4t3 = (path + "all_s3_IC31.nii").c_str();
        string nii_c5t1 = (path + "all_s1_IC39.nii").c_str();
        string nii_c5t2 = (path + "all_s2_IC39.nii").c_str();
        string nii_c5t3 = (path + "all_s3_IC39.nii").c_str();
        // Takes the string created above (1st param) and loads it into a texture (2nd param)
        NiftiUtils::read_nifti_file(nii_brain, brain);
        NiftiUtils::read_nifti_file(nii_c1t1, cluster1_time1);
        NiftiUtils::read_nifti_file(nii_c1t2, cluster1_time2);
        NiftiUtils::read_nifti_file(nii_c1t3, cluster1_time3);
        NiftiUtils::read_nifti_file(nii_c2t1, cluster2_time1);
        NiftiUtils::read_nifti_file(nii_c2t2, cluster2_time2);
        NiftiUtils::read_nifti_file(nii_c2t3, cluster2_time3);
        NiftiUtils::read_nifti_file(nii_c3t1, cluster3_time3);
        NiftiUtils::read_nifti_file(nii_c3t2, cluster3_time2);
        NiftiUtils::read_nifti_file(nii_c3t3, cluster3_time1);
        NiftiUtils::read_nifti_file(nii_c4t1, cluster4_time3);
        NiftiUtils::read_nifti_file(nii_c4t2, cluster4_time2);
        NiftiUtils::read_nifti_file(nii_c4t3, cluster4_time3);
        NiftiUtils::read_nifti_file(nii_c5t1, cluster5_time1);
        NiftiUtils::read_nifti_file(nii_c5t2, cluster5_time2);
        NiftiUtils::read_nifti_file(nii_c5t3, cluster5_time3);
    } // end of void loadNiftiInto3DTextures(string path)


    /******************************************************
     * Creates a Program object, then links the attached shaders to that object
     * This in effect prepares our shaders
     */
    void loadProgram(Program &p, const std::string &name) {

        p.create();  // This creates an 'empty' Program object

        // This attaches a shader object to the Program object
        //  p.loadText is doing what it sounds like...
        p.attach(p.loadText(name + ".vsh"), GL_VERTEX_SHADER);

        // This is effectively binding a named attribute variable ("vertexPosition"), with
        // a generic attribute index (posLoc)
        //VVVV--p.id() returns a GLuint! Its basically the Program objects ID number
        glBindAttribLocation(p.id(), posLoc, "vertexPosition");
        glBindAttribLocation(p.id(), texCoordLoc, "vertexTexCoord");

        p.attach(p.loadText(name + ".fsh"), GL_FRAGMENT_SHADER);

        // This is effectively linking the Program object to the attached Shader Objects
        // thereby creating shader executables which will be then be run by the GPU
        // Additionally, it maps uniforms and attributes to their Program id
        p.link();
    } // end of loadProgram


    /******************************************************
     *  Loads available nifti images into 3D textures,
     *  then builds a texture
     */
    void onCreate() {
        loadNiftiInto3DTextures(RESOURCES + "nifti/"); // load the nifti images into textures
        loadProgram(program, RESOURCES + "textureSlices2");

        camera = Camera(60.0,
                width / (height * 0.5),
                0.001,
                100.0).translateZ(-cameraZ).convergence(10.0).eyeSep(1.0 / 30.0 * 10.0);

        createSlices(numSlices);

        textureRotation = glm::mat4();
        textureRotationStart = glm::mat4();

        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_SCISSOR_TEST);

        int nnn;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &nnn);
        printf("num = %d\n", nnn);

    } // end of onCreate


    void createSlices(int num) {

        //if DEPTH_TEST is enables, must sort back to front

        numSlices = num;
        mbs.clear();
        mbs.resize(num);

        float zSt = orbitRadius / 2.0;  // Z-slice thickness?
        float zInc = (orbitRadius) / ((float) numSlices - 1);  // Z Increment?

        float sz = 4.0; //0.5;  Size? Of something...

        float tczInc = 1.0 / ((float) numSlices - 1);


        for (int i = 0; i < numSlices; i++) {
            MeshData md = MeshUtils::makeRectangle(vec3(-sz, -sz, zSt - (zInc * i)), //
                    vec3(sz, sz, zSt - (zInc * i)),   //
                    vec3(-0.15, -0.15, tczInc * i),   //
                    vec3(1.15, 1.15, tczInc * i));      //

            mbs[i].init(md, posLoc, -1, texCoordLoc, -1);
        }
    } // Angus createSlices


    void draw(mat4 useproj, mat4 useview) {

        program.bind();
        {

            glUniformMatrix4fv(program.uniform("proj"), 1, 0, ptr(useproj));
            glUniformMatrix4fv(program.uniform("view"), 1, 0, ptr(useview));
            glUniformMatrix4fv(program.uniform("textureRotation"), 1, 0, ptr(textureRotation));

            glUniform1f(program.uniform("percent"), percent);
            glUniform1f(program.uniform("opacity"), opacity);

            glUniform1i(program.uniform("useCluster1"), useCluster1);
            glUniform1i(program.uniform("useCluster2"), useCluster2);
            glUniform1i(program.uniform("useCluster3"), useCluster3);
            glUniform1i(program.uniform("useCluster4"), useCluster4);

            glUniform1i(program.uniform("brain"), 0);
            glUniform1i(program.uniform("cluster1_time1"), 1);
            glUniform1i(program.uniform("cluster1_time2"), 2);
            glUniform1i(program.uniform("cluster1_time3"), 3);

            glUniform1i(program.uniform("cluster2_time1"), 4);
            glUniform1i(program.uniform("cluster2_time2"), 5);
            glUniform1i(program.uniform("cluster2_time3"), 6);

            glUniform1i(program.uniform("cluster3_time1"), 7);
            glUniform1i(program.uniform("cluster3_time2"), 8);
            glUniform1i(program.uniform("cluster3_time3"), 9);

            glUniform1i(program.uniform("cluster4_time1"), 10);
            glUniform1i(program.uniform("cluster4_time2"), 11);
            glUniform1i(program.uniform("cluster4_time3"), 12);

            glUniform1i(program.uniform("cluster5_time1"), 13);
            glUniform1i(program.uniform("cluster5_time2"), 14);
            glUniform1i(program.uniform("cluster5_time3"), 15);

            brain.bind(GL_TEXTURE0);
            {
                cluster1_time1.bind(GL_TEXTURE1);
                cluster1_time2.bind(GL_TEXTURE2);
                cluster1_time3.bind(GL_TEXTURE3);
                cluster2_time1.bind(GL_TEXTURE4);
                cluster2_time2.bind(GL_TEXTURE5);
                cluster2_time3.bind(GL_TEXTURE6);
                cluster3_time1.bind(GL_TEXTURE7);
                cluster3_time2.bind(GL_TEXTURE8);
                cluster3_time3.bind(GL_TEXTURE9);
                cluster4_time1.bind(GL_TEXTURE10);
                cluster4_time2.bind(GL_TEXTURE11);
                cluster4_time3.bind(GL_TEXTURE12);
                cluster5_time1.bind(GL_TEXTURE13);
                cluster5_time2.bind(GL_TEXTURE14);
                cluster5_time3.bind(GL_TEXTURE15);
            }
            for (int i = 0; i < numSlices; i++) {
                mbs[i].draw();
            }

            brain.unbind(GL_TEXTURE0);
            {
                cluster1_time1.unbind(GL_TEXTURE1);
                cluster1_time2.unbind(GL_TEXTURE2);
                cluster1_time3.unbind(GL_TEXTURE3);
                cluster2_time1.unbind(GL_TEXTURE4);
                cluster2_time2.unbind(GL_TEXTURE5);
                cluster2_time3.unbind(GL_TEXTURE6);
                cluster3_time1.unbind(GL_TEXTURE7);
                cluster3_time2.unbind(GL_TEXTURE8);
                cluster3_time3.unbind(GL_TEXTURE9);
                cluster4_time1.unbind(GL_TEXTURE10);
                cluster4_time2.unbind(GL_TEXTURE11);
                cluster4_time3.unbind(GL_TEXTURE12);
                cluster5_time1.unbind(GL_TEXTURE13);
                cluster5_time2.unbind(GL_TEXTURE14);
                cluster5_time3.unbind(GL_TEXTURE15);
            }

        }
        program.unbind();
    } // end of void draw()


    //every 1/60th of a second...
    void onFrame() {
        handleKeys();
        handleMouse();

        if (camera.isTransformed) {
            camera.transform();
        }

        if (!USE_STEREO) {
            glViewport(0, 0, width, height);
            {
                glScissor(0, 0, width, height);

                glClearColor(0.0, 0.0, 0.0, 1.0);

                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

                draw(camera.projection, camera.view);
            }
        } else {
            //Trying out passive stereo...
            glViewport(0, 0, width / 2.0, height);
            {
                glScissor(0, 0, width / 2.0, height);
                glClearColor(0.0, 0.0, 0.0, 1.0);

                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

                draw(camera.leftProjection, camera.leftView);
            }

            glViewport(width / 2.0, 0, width / 2.0, height);
            {
                glScissor(width / 2.0, 0, width / 2.0, height);
                glClearColor(0.0, 0.0, 0.0, 1.0);
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

                draw(camera.rightProjection, camera.rightView);
            }
        }
    }  // end of onFrame

    /******************************
    *
    *   Currently Unused
    **/
    void onReshape() {
        camera.perspective(60.0, width / (height * 0.5), 0.001, 100.0).stereo(USE_STEREO);
    } // Angus version



    /*****************************
    *
    * Takes care of Mouse interactions
    **/
    void handleMouse() {
        bool movingLeft = false;
        bool movingRight = false;
        bool movingUp = false;
        bool movingDown = false;

        if (abs(mouseX - previousMouseX) > abs(mouseY - previousMouseY)) {
            if (mouseX < previousMouseX) {
                movingLeft = true;
            } else {
                movingRight = true;
            }
        } else {
            if (mouseY < previousMouseY) {
                movingUp = true;
            } else {
                movingDown = true;
            }
        }

        if (isDragging) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            if (movingLeft) {
                textureRotation = glm::rotate(textureRotation, -3.0f, vec3(0.0, 1.0, 0.0));
            } else if (movingRight) {
                textureRotation = glm::rotate(textureRotation, 3.0f, vec3(0.0, 1.0, 0.0));
            }

            if (movingUp) {
                textureRotation = glm::rotate(textureRotation, 3.0f, vec3(1.0, 0.0, 0.0));
            } else if (movingDown) {
                textureRotation = glm::rotate(textureRotation, -3.0f, vec3(1.0, 0.0, 0.0));
            }
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (isMoving) {
//            printf("X: %d, Y: %d\n", mouseX, mouseY);
            isMoving = false; //isn't a listener that can hear when a mouse *stops*?
        }
    } // end of handleMouse


    void handleKeys() {
        handleKeys_auxilliary();
        handleKeys_wasdqe();
        handleKeys_arrows();
        if (percent >= 1.0) {
            percent = 1.0;
        } else if (percent <= 0.0) {
            percent = 0.0;
        }

        if (opacity >= 1.0) {
            opacity = 1.0;
        } else if (opacity <= 0.0) {
            opacity = 0.0;
        }
    }


    void handleKeys_wasdqe() {
        float dg = 1.0f;

        if (keysDown[kVK_Shift]) {
            dg = 3.0f;
        }

        if (keysDown[kVK_ANSI_W]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(1.0, 0.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_S]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(1.0, 0.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_A]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(0.0, 1.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_D]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(0.0, 1.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_Q]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(0.0, 0.0, 1.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_E]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(0.0, 0.0, 1.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

    }

    /*
       Dianne wanted the arrow keys to be usable for 'Old' People...they only provide
       basic tranlations and rotations, nothing exciting
    */
    void handleKeys_arrows() {

        float dg = 1.0f;
        if (keysDown[kVK_Shift]) {
            dg = 3.0f;
        }

        if (keysDown[kVK_UpArrow]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(1.0, 0.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_DownArrow]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(1.0, 0.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_LeftArrow]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(0.0, 1.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_RightArrow]) {
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(0.0, 1.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }
    }

    void handleKeys_auxilliary() {
        float amt = 0.001;
        float dg = 0.05;
        if (keysDown[kVK_ANSI_X]) {
            amt = -0.001;
            dg = -0.05;
        }

        if (keysDown[kVK_ANSI_O]) {
            opacity += amt;
            printf("keypad + %f\n", opacity);
        }

        // Increase the Percent
        if (keysDown[kVK_ANSI_P]) {
            percent += amt;
            printf("keypad * %f\n", percent);
        }

        // Increase Z!
        if (keysDown[kVK_ANSI_Z]) {
            camera.translateZ(dg);
            std::cout << "Zooming in!..." << glm::to_string(camera.posVec) << "\n";
        }

        // Take us home!
        if (keysDown[kVK_ANSI_KeypadEnter]) {
            textureRotation = textureRotationStart;
            camera.resetVectors();
            camera.translateZ(-5.000000);
            opacity = 0.1;
            percent = 0.0;

        }

        if (keysDown[kVK_Space]) {
            printf("Nothing at all...\n");
            // if (([drawerLeftSide state] == NSDrawerOpenState))  {
            //     [drawerLeftSide close];
            //     printf("Closing Left drawer..\n");
            // } else if (([drawerLeftSide state] == NSDrawerClosedState)) {
            //     printf("Opening Left drawer..\n");
            //     [drawerLeftSide open];
            // } else {
            //   toggleDrawer();
            // }
        }

        // /*   Decreasing values   */
        //     //  Decrease the Opacity
        //     if (keysDown[kVK_Shift] && keysDown[kVK_ANSI_O]) {
        //         opacity -= 0.001;
        //         printf("keypad - %f\n", opacity);
        //     }

        //     // Decrease the Percent
        //     if (keysDown[kVK_ANSI_O] && keysDown[kVK_ANSI_P]) {
        //         percent -= 0.001;
        //         printf("keypad / %f\n", percent);
        //     }

        //     // Decrease Z!
        //     if (keysDown[kVK_ANSI_X] && keysDown[kVK_ANSI_P]) {
        //         camera.translateZ(-0.05);
        //         cout << "Zooming out!..." << glm::to_string(camera.posVec) << "\n";
        //     }

    }

    /**** Begin function definitions ****/

//    void toggleDrawer() {
//        // std::cout << [drawerLeftSide state] << std::endl;
//
//       if (([drawerLeftSide state] == NSDrawerOpenState) &&
//           ([drawerBottomSide state] == NSDrawerOpenState))  {
//           [drawerLeftSide close];
//           [drawerBottomSide close];
//           printf("Closing Left drawer..\n");
//       } else if (([drawerLeftSide state] == NSDrawerClosedState) &&
//                  ([drawerBottomSide state] == NSDrawerOpenState)) {
//            [drawerBottomSide close];
//            printf("Closing Right drawer..\nOpening Left drawer..\n");
//            [drawerLeftSide open];
//       } else if (([drawerBottomSide state] == NSDrawerClosedState) &&
//                  ([drawerLeftSide state] == NSDrawerOpenState)) {
//            [drawerLeftSide close];
//            printf("Closing Left drawer..\nOpening Right drawer..\n");
//            [drawerBottomSide open];
//       } else if (([drawerBottomSide state] == NSDrawerClosedState) &&
//                  ([drawerLeftSide state] == NSDrawerClosedState)) {
//            [drawerLeftSide open];
//            printf("Opening Left drawer..\n");
//       }
//    }


    void toggleDrawer() {
        if (([drawerLeftSide state] == NSDrawerOpenState)) {
            [drawerLeftSide close];
            printf("Closing Left drawer..\n");
        } else if (([drawerLeftSide state] == NSDrawerClosedState)) {
            [drawerLeftSide open];
            printf("Opening Left drawer..\n");
        }
    }


    // Toggle clusters on, and off
    // this is an ActionProxy function
    void toggleClusters() {
        whichClusters = (whichClusters + 1) % 3;
        if (whichClusters == 0) {
            useCluster1 = 1;
            useCluster2 = 1;
        } else if (whichClusters == 1) {
            useCluster1 = 1;
            useCluster2 = 0;
        } else {
            useCluster1 = 0;
            useCluster2 = 1;
        }
        printf("in toggleClusters... u1 = %d, u2 = %d\n", useCluster1, useCluster2);
    } // end of toggleClusters()


    void toggleTime1() {
        // whichClusters = (whichClusters+1) % 3;
        if (useCluster1 == 0) {
            useCluster1 = 1;
        } else {
            useCluster1 = 0;
        }
        printf("In toggleTime1, useCluster1 %d\n", useCluster1);
    }

    void toggleTime2() {
        // whichClusters = (whichClusters+1) % 3;
        if (useCluster2 == 0) {
            useCluster2 = 1;
        } else {
            useCluster2 = 0;
        }
        printf("In toggleTime2, useCluster2 %d\n", useCluster2);
    }

    void toggleTime3() {
        // whichClusters = (whichClusters+1) % 3;
        if (useCluster3 == 0) {
            useCluster3 = 1;
        } else {
            useCluster3 = 0;
        }
        printf("In toggleTime3, useCluster3 %d\n", useCluster3);
    }

    void toggleTime4() {
        // whichClusters = (whichClusters+1) % 3;
        if (useCluster4 == 0) {
            useCluster4 = 1;
        } else {
            useCluster4 = 0;
        }
        printf("In toggleTime4, useCluster4 %d\n", useCluster4);
    }

    void toggleTime5() {
        // whichClusters = (whichClusters+1) % 3;
        if (useCluster5 == 0) {
            useCluster5 = 1;
        } else {
            useCluster5 = 0;
        }
        printf("In toggleTime5, useCluster5 %d\n", useCluster5);
    }


    void adjustOpacity() {
        printf("In adjustOpacity, slider is == %f\n", [opacitySlider floatValue]);
        opacity = [opacitySlider floatValue];
    }


    void adjustPercent() {
        printf("In adjustPercent, slider is == %f\n", [percentSlider floatValue]);
        percent = [percentSlider floatValue];
    }


    void initializeViews() {
        // This was a really helpful resource
        // http://stackoverflow.com/questions/349927/programmatically-creating-controls-in-cocoa
        // http://stackoverflow.com/questions/717442/how-do-i-create-cocoa-interfaces-without-interface-builder

        NSView *glv = makeGLView(400, 300);
        ActionProxy *proxy = [[ActionProxy alloc] init:[NSValue valueWithPointer:this]];

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        id appName = @"ICA Time Series";

        // Set up the window to hold the CocoaGL view
        id window = [CocoaGL setUpAppWindow:appName
                                          x:100
                                          y:100
                                          w:400
                                          h:300];

        [CocoaGL setUpMenuBar:(CocoaGL *) glv name:appName];

        // need to look into how to autoresize the window, until then its not useful to use a regular view,
        // we are stuck with NSSplitView
        // *parentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        // setContentView:parentView];
        NSSplitView *parentView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        [parentView setVertical:YES];
        [window setContentView:parentView];

        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(400, 300, 200, 300)];

//        NSView *viewDrawerBottom = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 360)];  // This is a view for the drawer
        NSView *viewDrawerLeft = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 360)];  // This is a view for the drawer


        drawerLeftSide = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200.0, 150.0) preferredEdge:NSMinXEdge];  // Now if only I could get the drawer on the left side...
        [drawerLeftSide setContentView:viewDrawerLeft];
        [drawerLeftSide setParentWindow:window];
        [drawerLeftSide open];

        // Trying to get a button to toggle the drawer open and closed
        //  NSButton* buttonToggleDrawer = [[NSButton alloc] initWithFrame: NSMakeRect(150, 200, 40, 90)];
        NSButton *buttonToggleDrawer = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 90, 40)];
        buttonToggleDrawer.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleDrawer setButtonType:NSToggleButton];
        [buttonToggleDrawer setTitle:@"Close"];
        [buttonToggleDrawer setAlternateTitle:@"Open"];
        [buttonToggleDrawer setTarget:proxy];
        [buttonToggleDrawer setAction:@selector(toggleDrawer:)];
        [view addSubview:buttonToggleDrawer];

        /*
            Making Check boxes to control which clusters I see
            For the sake a brevity, Im only going to comment one button as they both do essentially the same thing
        */

        // Setting up the button to toggle time 1
        NSButton *buttonToggleTime1 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 210, 90, 40)];  // Instantiate it, and describe its size and location
        buttonToggleTime1.bezelStyle = NSRoundedBezelStyle;     // sets the bezelStyle
        [buttonToggleTime1 setButtonType:NSSwitchButton];      // sets the button Type, I wanted a SwitchButton
        [buttonToggleTime1 setTitle:@"Comp 4"];  // Good to know, I can call @"SomeString" and it will cast it as NSString
        [buttonToggleTime1 setTarget:proxy];        // link it to ActionProxy
        [buttonToggleTime1 setState:NSOffState];     // I want the button to be 'On' when it is displaying a color
        [buttonToggleTime1 setAction:@selector(toggleTime1:)];      // link the method
        [viewDrawerLeft addSubview:buttonToggleTime1];  //  add it to the drawer view

        // Setting up the button to toggle time 2
        NSButton *buttonToggleTime2 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 180, 90, 40)];
        buttonToggleTime2.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime2 setButtonType:NSSwitchButton];
        [buttonToggleTime2 setTitle:@"Comp 11"];
        [buttonToggleTime2 setTarget:proxy];
        [buttonToggleTime2 setState:NSOffState];
        [buttonToggleTime2 setAction:@selector(toggleTime2:)];
        [viewDrawerLeft addSubview:buttonToggleTime2]; // [viewMain addSubview:buttonToggleTime2];

        // Setting up the button to toggle time 2
        NSButton *buttonToggleTime3 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 150, 90, 40)];
        buttonToggleTime3.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime3 setButtonType:NSSwitchButton];
        [buttonToggleTime3 setTitle:@"Comp 12"];
        [buttonToggleTime3 setTarget:proxy];
        [buttonToggleTime3 setState:NSOffState];
        [buttonToggleTime3 setAction:@selector(toggleTime3:)];
        [viewDrawerLeft addSubview:buttonToggleTime3]; // [viewMain addSubview:buttonToggleTime2];

        // Setting up the button to toggle time 2
        NSButton *buttonToggleTime4 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 120, 90, 40)];
        buttonToggleTime4.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime4 setButtonType:NSSwitchButton];
        [buttonToggleTime4 setTitle:@"Comp 18"];
        [buttonToggleTime4 setTarget:proxy];
        [buttonToggleTime4 setState:NSOffState];
        [buttonToggleTime4 setAction:@selector(toggleTime4:)];
        [viewDrawerLeft addSubview:buttonToggleTime4]; // [viewMain addSubview:buttonToggleTime2];

        NSButton *buttonToggleTime5 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 90, 90, 40)];
        buttonToggleTime5.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime5 setButtonType:NSSwitchButton];
        [buttonToggleTime5 setTitle:@"Comp 25"];
        [buttonToggleTime5 setTarget:proxy];
        [buttonToggleTime5 setState:NSOffState];
        [buttonToggleTime5 setAction:@selector(toggleTime5:)];
        [viewDrawerLeft addSubview:buttonToggleTime5]; // [viewMain addSubview:buttonToggleTime2];

        // Setting up the Opacity slider
        opacitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 30, 90, 40)];
        [opacitySlider setMinValue:0.0];
        [opacitySlider setMaxValue:1];
        [opacitySlider setTarget:proxy];
        [opacitySlider setNumberOfTickMarks:6];
        [opacitySlider setAllowsTickMarkValuesOnly:NO];
        [opacitySlider setAction:@selector(adjustOpacity:)];
        [viewDrawerLeft addSubview:opacitySlider];  // [viewMain addSubview:opacitySlider];

        // Setting up the Percent slider
        percentSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 0, 90, 40)];
        [percentSlider setMinValue:0.0];
        [percentSlider setMaxValue:1];
        [percentSlider setTarget:proxy];
        [percentSlider setNumberOfTickMarks:4];
        [percentSlider setAllowsTickMarkValuesOnly:YES];
        [percentSlider setAction:@selector(adjustPercent:)];
        [viewDrawerLeft addSubview:percentSlider];  // [viewMain addSubview:percentSlider];

        [[window contentView] addSubview:glv];
        [[window contentView] addSubview:view];
        [NSApp activateIgnoringOtherApps:YES]; //brings application to front on startup
        [NSApp run];

    }
};
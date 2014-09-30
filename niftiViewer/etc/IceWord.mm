/**
 * Program Name: IceWord.mm
 *       Author: Kyle Reese Almryde
 *  Description: This is implementation of the niftiViewer prototype includes
 *               the IceWord1 ICA data. This implementation uses volume
 *               raycasting to render in both stereographic and mono-graphic
 *               projections. It requires the IceWord.{f,v}sh shader files
 *               to render brain on it.
 */


#include "Includes.hpp"

#include "MeshBuffer.hpp"
#include "MeshUtils.hpp"
#include "Program.hpp"
#include "Shapes.hpp"
#include "Camera.hpp"
#include "ResourceHandler.h"
#include "NiftiUtils.h"
#include "ActionProxy.h"
#define BUFFER_OFFSET(i) (reinterpret_cast<void*>(i))


using namespace aluminum;

class IceWord : public RendererOSX {

public:

    GLuint posLoc = 0;
    GLuint cubeVBOID;
    GLuint cubeVAOID;
    GLuint cubeIndicesID;

// MNI_caez_N27
//    const int XDIM = 151;
//    const int YDIM = 188;
//    const int ZDIM = 154;

// MNI_SurfVol
    // const int XDIM = 256;
    // const int YDIM = 256;
    // const int ZDIM = 256;

// MNI_2mm
   const int XDIM = 91;
   const int YDIM = 109;
   const int ZDIM = 91;

    bool c1_on = true;
    bool c2_on = true;
    bool c3_on = true;
    bool c4_on = true;
    bool c5_on = true;

    float dist = 2;

    float rX = -84.0;
    float rY = 2.50;
    float rZ = -79.50;

    float timePerc = 0.0; //can be between 0 and 1

    float xyzIncrement = 7.00;
    float cameraIncrement = 0.05;

    float brainOpacity = 1.0;

    glm::vec3 camPos;
    glm::mat4 Rx, Ry, M, MV, MVP;
    mat4 proj, model, view;
    glm::vec4 bg = glm::vec4(0.0);

    // R,    G,    B,   A
    vec4 clusterColors[5] = {
            vec4(1.00, 0.00, 0.0, 1.0),  // Red
            vec4(0.00, 0.00, 1.0, 1.0),  // Blue
            vec4(1.00, 1.00, 0.0, 1.0),  // Yellow
            vec4(0.00, 1.00, 0.0, 1.0)};  // Green


    NSSlider *opacitySlider;
    NSSlider *timeSlider;
    NSDrawer *drawerLeftSide;

    Camera camera;
    Program program;

    Texture images[21];
    Texture brain;
    Texture comp0_timeA, comp0_timeB, comp0_timeC, comp0_timeD;
    Texture comp1_timeA, comp1_timeB, comp1_timeC, comp1_timeD;
    Texture comp2_timeA, comp2_timeB, comp2_timeC, comp2_timeD;
    Texture comp3_timeA, comp3_timeB, comp3_timeC, comp3_timeD;

    bool USE_STEREO = false;
    string RESOURCES = (string) [NSHomeDirectory() UTF8String] + "/Dropbox/XCodeProjects/aluminum/osx/examples/niftiViewer-KrbA/resources/";


    void loadProgram(Program &p, const std::string &name) {

        p.create();
        p.attach(p.loadText(name + ".vsh"), GL_VERTEX_SHADER);
        glBindAttribLocation(p.id(), posLoc, "vertexPosition");
        p.attach(p.loadText(name + ".fsh"), GL_FRAGMENT_SHADER);

        p.link();
    }

    // add Percent score here
    void loadNiftiInto3DTextures(string path) {

        // Anatomical Image
        // NiftiUtils::read_nifti_file((path + "MNI_caez_N27.nii").c_str(), brain);
        NiftiUtils::read_nifti_file((path + "brains/MNI_2mm.nii").c_str(), brain);

        // TimeA Images
        NiftiUtils::read_nifti_file((path + "ice/IC4_s1_2.6503.nii").c_str(), comp0_timeA);
        NiftiUtils::read_nifti_file((path + "ice/IC11_s1_2.6503.nii").c_str(), comp1_timeA);
        NiftiUtils::read_nifti_file((path + "ice/IC12_s1_2.6503.nii").c_str(), comp2_timeA);
        NiftiUtils::read_nifti_file((path + "ice/IC18_s1_2.6503.nii").c_str(), comp3_timeA);

        // TimeB Images
        NiftiUtils::read_nifti_file((path + "ice/IC4_s2_2.6503.nii").c_str(), comp0_timeB);
        NiftiUtils::read_nifti_file((path + "ice/IC11_s2_2.6503.nii").c_str(), comp1_timeB);
        NiftiUtils::read_nifti_file((path + "ice/IC12_s2_2.6503.nii").c_str(), comp2_timeB);
        NiftiUtils::read_nifti_file((path + "ice/IC18_s2_2.6503.nii").c_str(), comp3_timeB);

        // TimeC Images
        NiftiUtils::read_nifti_file((path + "ice/IC4_s3_2.6503.nii").c_str(), comp0_timeC);
        NiftiUtils::read_nifti_file((path + "ice/IC11_s3_2.6503.nii").c_str(), comp1_timeC);
        NiftiUtils::read_nifti_file((path + "ice/IC12_s3_2.6503.nii").c_str(), comp2_timeC);
        NiftiUtils::read_nifti_file((path + "ice/IC18_s3_2.6503.nii").c_str(), comp3_timeC);

        // TimeC Images
        NiftiUtils::read_nifti_file((path + "ice/IC4_s4_2.6503.nii").c_str(), comp0_timeD);
        NiftiUtils::read_nifti_file((path + "ice/IC11_s4_2.6503.nii").c_str(), comp1_timeD);
        NiftiUtils::read_nifti_file((path + "ice/IC12_s4_2.6503.nii").c_str(), comp2_timeD);
        NiftiUtils::read_nifti_file((path + "ice/IC18_s4_2.6503.nii").c_str(), comp3_timeD);
    }

    void onCreate() {

        loadNiftiInto3DTextures(RESOURCES + "nifti/");
        loadProgram(program, RESOURCES + "iceword");
        camera = Camera(60.0, (float) width / height, 0.001, 100.0).translateZ(-dist).convergence(10.0).eyeSep(1.0 / 30.0 * 10.0);
        proj = camera.projection;
//        proj = glm::perspective(45.0f, 1.0f, 0.1f, 150.0f);

        glClearColor(bg.r, bg.g, bg.b, bg.a);

        //setup unit cube vertex array and vertex buffer objects
        glGenVertexArrays(1, &cubeVAOID);
        glGenBuffers(1, &cubeVBOID);
        glGenBuffers(1, &cubeIndicesID);

        //unit cube vertices
        glm::vec3 vertices[8] = {
                glm::vec3(-0.5f, -0.5f, -0.5f),
                glm::vec3(0.5f, -0.5f, -0.5f),
                glm::vec3(0.5f, 0.5f, -0.5f),
                glm::vec3(-0.5f, 0.5f, -0.5f),
                glm::vec3(-0.5f, -0.5f, 0.5f),
                glm::vec3(0.5f, -0.5f, 0.5f),
                glm::vec3(0.5f, 0.5f, 0.5f),
                glm::vec3(-0.5f, 0.5f, 0.5f)
        };

        //unit cube indices
        GLushort cubeIndices[36] = {
                0, 5, 4,
                5, 0, 1,
                3, 7, 6,
                3, 6, 2,
                7, 4, 6,
                6, 4, 5,
                2, 1, 3,
                3, 1, 0,
                3, 0, 7,
                7, 0, 4,
                6, 5, 2,
                2, 5, 1
        };

        glBindVertexArray(cubeVAOID);
        glBindBuffer(GL_ARRAY_BUFFER, cubeVBOID);
        //pass cube vertices to buffer object memory
        glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), &(vertices[0].x), GL_STATIC_DRAW);

        //enable vertex attributre array for position
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, 0);

        //pass indices to element array  buffer
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cubeIndicesID);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeIndices), &cubeIndices[0], GL_STATIC_DRAW);

        glBindVertexArray(0);


    }

    void onFrame() {
        handleMouse();
        handleKeys();

        if (camera.isTransformed) {
            camera.transform();
        }

        // glm::vec3 camPos;
        // glm::mat4 Rx, Ry, M, MV, MVP;

        if (!USE_STEREO) {
            glViewport(0, 0, (GLsizei) width, (GLsizei) height);
            glScissor(0, 0, width, height);
            glClearColor(0.0, 0.0, 0.0, 1.0);

            //set the model transform
            Rx = glm::rotate(mat4(1.0f), rX, glm::vec3(1.0f, 0.0f, 0.0f));
            Ry = glm::rotate(Rx, rY, glm::vec3(0.0f, 1.0f, 0.0f));
            M = glm::rotate(Ry, rZ, glm::vec3(0.0f, 0.0f, 1.0f));

            MV = camera.view * M;

            //get the camera position
            camPos = glm::vec3(glm::inverse(MV) * glm::vec4(0, 0, 0, 1));

            //get the combined modelview projection matrix
            MVP = proj * MV;

            // render the scene
            draw(MVP, camPos);
        } else {
            //set the model transform
            glViewport(0, 0, (GLsizei) (width / 2.0), height);
            {
                glScissor(0, 0, (GLsizei) (width / 2.0), height);
                glClearColor(0.0, 0.0, 0.0, 1.0);

                Rx = glm::rotate(mat4(1.0f), rX, glm::vec3(1.0f, 0.0f, 0.0f));
                Ry = glm::rotate(Rx, rY, glm::vec3(0.0f, 1.0f, 0.0f));
                M = glm::rotate(Ry, rZ, glm::vec3(0.0f, 0.0f, 1.0f));
                MV = camera.leftView * M;

                //get the combined modelview projection matrix
                MVP = camera.leftProjection * MV;

                //get the camera position
                camPos = glm::vec3(glm::inverse(MV) * glm::vec4(0, 0, 0, 1));

                // render the scene
                draw(MVP, camPos);

            }
            glViewport((GLint) (width / 2.0), 0, (GLint) (width / 2.0), height);
            {
                glScissor((GLsizei) (width / 2.0), 0, (GLsizei) (width / 2.0), height);
                glClearColor(0.0, 0.0, 0.0, 1.0);

                Rx = glm::rotate(mat4(1.0f), rX, glm::vec3(1.0f, 0.0f, 0.0f));
                Ry = glm::rotate(Rx, rY, glm::vec3(0.0f, 1.0f, 0.0f));
                M = glm::rotate(Ry, rZ, glm::vec3(0.0f, 0.0f, 1.0f));
                MV = camera.rightView * M;

                //get the combined modelview projection matrix
                MVP = camera.rightProjection * MV;

                //get the camera position
                camPos = glm::vec3(glm::inverse(MV) * glm::vec4(0, 0, 0, 1));

                // render the scene
                draw(MVP, camPos);
            }
        }
    }


    void draw(mat4 MVP, vec3 camPos) {
        float tpx3 = (timePerc * 3.0); // 0-1
        float tpm3x3 = ((timePerc - 0.33333) * 3.0); // 1 - 0
        float tpx3m2 = (timePerc * 3.0) - 2.0; // 1-0

//       printf("tp %f tpx3 %f tpm3x3 %f tpx3m2 %f\n", timePerc, tpx3, tpm3x3, tpx3m2);

        glClear(GL_COLOR_BUFFER_BIT| GL_DEPTH_BUFFER_BIT);

        //enable blending and bind the cube vertex array object
        glEnable(GL_BLEND);

        //enable depth test
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_SCISSOR_TEST);

        //set the over blending function
        glDepthFunc(GL_LEQUAL);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        glBindVertexArray(cubeVAOID);


        //bind the raycasting shader
        program.bind();
        {
            //pass shader uniforms
            glUniformMatrix4fv(program.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP));
            glUniform3f(program.uniform("camPos"), camPos.x, camPos.y, camPos.z);
            glUniform3f(program.uniform("step_size"), 1.0f / XDIM, 1.0f / YDIM, 1.0f / ZDIM);
            glUniform1f(program.uniform("brainOpacity"), brainOpacity);

            glUniform1f(program.uniform("timePerc"), timePerc);
            glUniform1f(program.uniform("tpx3"), tpx3);
            glUniform1f(program.uniform("tpm3x3"), tpm3x3);
            glUniform1f(program.uniform("tpx3m2"), tpx3m2);

            glUniform1i(program.uniform("MAX_SAMPLES"), 300);

            glUniform4f(program.uniform("c1_color"), clusterColors[0].r, clusterColors[0].g, clusterColors[0].b, clusterColors[0].a);
            glUniform4f(program.uniform("c2_color"), clusterColors[1].r, clusterColors[1].g, clusterColors[1].b, clusterColors[1].a);
            glUniform4f(program.uniform("c3_color"), clusterColors[2].r, clusterColors[2].g, clusterColors[2].b, clusterColors[2].a);
            glUniform4f(program.uniform("c4_color"), clusterColors[3].r, clusterColors[3].g, clusterColors[3].b, clusterColors[3].a);

            //pass constant uniforms at initialization
            glUniform1i(program.uniform("volume"), 0);
            glUniform1i(program.uniform("c1_tA"), 1);
            glUniform1i(program.uniform("c2_tA"), 2);
            glUniform1i(program.uniform("c3_tA"), 3);
            glUniform1i(program.uniform("c4_tA"), 4);

            glUniform1i(program.uniform("c1_tB"), 6);
            glUniform1i(program.uniform("c2_tB"), 7);
            glUniform1i(program.uniform("c3_tB"), 8);
            glUniform1i(program.uniform("c4_tB"), 9);


//            A - - B - - C - - D
//            | / \ | \ / | \ / |
//            A     B     C     D
//            0    0.3   0.6    1
//            0     1     0     1
//            1     0     1     0

            //render the cube
            if (timePerc < 0.33) {
                // printf("timePerc: %f < 0.5! %f \n",timePerc, (timePerc * 2.0));
                brain.bind(GL_TEXTURE0);
                comp0_timeA.bind(GL_TEXTURE1);
                comp1_timeA.bind(GL_TEXTURE2);
                comp2_timeA.bind(GL_TEXTURE3);
                comp3_timeA.bind(GL_TEXTURE4);

                comp0_timeB.bind(GL_TEXTURE6);
                comp1_timeB.bind(GL_TEXTURE7);
                comp2_timeB.bind(GL_TEXTURE8);
                comp3_timeB.bind(GL_TEXTURE9);

                glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);

                brain.unbind(GL_TEXTURE0);
                comp0_timeA.unbind(GL_TEXTURE1);
                comp1_timeA.unbind(GL_TEXTURE2);
                comp2_timeA.unbind(GL_TEXTURE3);
                comp3_timeA.unbind(GL_TEXTURE4);

                comp0_timeB.unbind(GL_TEXTURE6);
                comp1_timeB.unbind(GL_TEXTURE7);
                comp2_timeB.unbind(GL_TEXTURE8);
                comp3_timeB.unbind(GL_TEXTURE9);

            } else if (timePerc < 0.66) {
                // printf("timePerc: %f >= 0.5! %f \n", timePerc, ((timePerc - 0.5) * 2.0));
                brain.bind(GL_TEXTURE0);
                comp0_timeB.bind(GL_TEXTURE1);
                comp1_timeB.bind(GL_TEXTURE2);
                comp2_timeB.bind(GL_TEXTURE3);
                comp3_timeB.bind(GL_TEXTURE4);

                comp0_timeC.bind(GL_TEXTURE6);
                comp1_timeC.bind(GL_TEXTURE7);
                comp2_timeC.bind(GL_TEXTURE8);
                comp3_timeC.bind(GL_TEXTURE9);

                glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);

                brain.unbind(GL_TEXTURE0);
                comp0_timeB.unbind(GL_TEXTURE1);
                comp1_timeB.unbind(GL_TEXTURE2);
                comp2_timeB.unbind(GL_TEXTURE3);
                comp3_timeB.unbind(GL_TEXTURE4);

                comp0_timeC.unbind(GL_TEXTURE6);
                comp1_timeC.unbind(GL_TEXTURE7);
                comp2_timeC.unbind(GL_TEXTURE8);
                comp3_timeC.unbind(GL_TEXTURE9);

            } else {
                brain.bind(GL_TEXTURE0);
                comp0_timeC.bind(GL_TEXTURE1);
                comp1_timeC.bind(GL_TEXTURE2);
                comp2_timeC.bind(GL_TEXTURE3);
                comp3_timeC.bind(GL_TEXTURE4);

                comp0_timeD.bind(GL_TEXTURE6);
                comp1_timeD.bind(GL_TEXTURE7);
                comp2_timeD.bind(GL_TEXTURE8);
                comp3_timeD.bind(GL_TEXTURE9);

                glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);

                brain.unbind(GL_TEXTURE0);
                comp0_timeC.unbind(GL_TEXTURE1);
                comp1_timeC.unbind(GL_TEXTURE2);
                comp2_timeC.unbind(GL_TEXTURE3);
                comp3_timeC.unbind(GL_TEXTURE4);

                comp0_timeD.unbind(GL_TEXTURE6);
                comp1_timeD.unbind(GL_TEXTURE7);
                comp2_timeD.unbind(GL_TEXTURE8);
                comp3_timeD.unbind(GL_TEXTURE9);

            }
            //unbind the raycasting shader

        }
        program.unbind();

//        glDisable(GL_BLEND);
//        glDisable(GL_DEPTH_TEST);
        glBindVertexArray(0);
    }




    void onReshape() {
        glViewport(0, 0, (GLsizei) width, (GLsizei) height);

        if (USE_STEREO)
            camera.perspective(60.0, (float) width / height, 0.001, 100.0).stereo(USE_STEREO);
        else {
            camera = Camera(60.0, (float) width / height, 0.001, 100.0).translate(camera.posVec);
            camera.perspective(60.0, (float) width / height, 0.001, 100.0).stereo(USE_STEREO);
        }

        proj = camera.projection;
    }

    void handleMouse() {
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

            if (movingLeft) rZ -= 2.0;
            else if (movingRight) rZ += 2.0;

            if (movingUp) rX += 2.0;
            else if (movingDown) rX -= 2.0;

            rX -= 0.5;
            rY -= 0.5;
            rZ -= 0.5;
        }

        if (isMoving) {
            //            printf("X: %d, Y: %d\n", mouseX, mouseY);
            isMoving = false; //isn't a listener that can hear when a mouse *stops*?
        }
    }


    void handleKeys() {

        // Adjust Brain Opacity -
        if (keysDown[kVK_ANSI_LeftBracket]) {
            if (brainOpacity > 0.0) {
                brainOpacity -= 0.01;
            } else {
                brainOpacity = 0.0;
            }
            cout << "bO = " << brainOpacity << endl;
            [opacitySlider setDoubleValue:brainOpacity];  // Sets the position of the Slider!
        }

        // Adjust Brain Opacity +
        if (keysDown[kVK_ANSI_RightBracket]) {
            if (brainOpacity < 1.0) {
                brainOpacity += 0.01;
            } else {
                brainOpacity = 1.0;
            }
            cout << "bO = " << brainOpacity << endl;
            [opacitySlider setDoubleValue:brainOpacity];  // Sets the position of the Slider!
        }

        // Adjust Time Perc -
        if (keysDown[kVK_ANSI_Comma]) {
            if (timePerc > 0.0) {
                timePerc -= 0.01;
            } else {
                timePerc = 0.0;
            }
            // cout << "timePerc = " << timePerc << endl;
            [timeSlider setDoubleValue:timePerc];
        }

        // Adjust Time Perc +
        if (keysDown[kVK_ANSI_Period]) {
            if (timePerc < 1.0) {
                timePerc += 0.01;
            } else {
                timePerc = 1.0;
            }
            // cout << "timePerc = " << timePerc << endl;
            [timeSlider setDoubleValue:timePerc];
        }
        if (keysDown[kVK_ANSI_0]) {
            camera.printCameraInfo();
            debugInfo();
        }

        /*************************************
        *  Camera Controls
        *  up/down,
        *  left,right,
        *  forward,backward,
        *  rotate left, rotate right
        **************************************/
        if (keysDown[kVK_ANSI_W]) {
            rX -= xyzIncrement; // Up
            camera.printCameraInfo();
            debugInfo();
        }
        if (keysDown[kVK_ANSI_S]) {
            rX += xyzIncrement; // Up
            camera.printCameraInfo();
            debugInfo();
        } // down

        if (keysDown[kVK_ANSI_A]) {
            rZ -= xyzIncrement; // Rotate right
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_D]) {
            rZ += xyzIncrement; // Rotate left
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_E]) {
            rY -= xyzIncrement; // left
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Q]) {
            rY += xyzIncrement; // right
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_Z]) {
            camera.translateZ(cameraIncrement);   // + Zoom
            camera.printCameraInfo();
            debugInfo();
        }
        if (keysDown[kVK_ANSI_X]) {
            camera.translateZ(-cameraIncrement);  // - Zoom
            camera.printCameraInfo();
            debugInfo();
        }

        // Rotate camera around scene
        if (keysDown[kVK_ANSI_I]) {
            camera.rotateX(cameraIncrement);  // Up
            camera.printCameraInfo();
            debugInfo();
        }
        if (keysDown[kVK_ANSI_K]){
            camera.rotateX(-cameraIncrement); // Down
            camera.printCameraInfo();
            debugInfo();
        }

        if (keysDown[kVK_ANSI_J]) {
            camera.rotateY(cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        } // Left

        if (keysDown[kVK_ANSI_L]) {
            camera.rotateY(-cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        }// Right

        if (keysDown[kVK_ANSI_U]) {
            camera.rotateZ(cameraIncrement);  // +Yaw
            camera.printCameraInfo();
            debugInfo();
        }
        if (keysDown[kVK_ANSI_O]) {
            camera.rotateZ(-cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        }// -Yaw


        // Rotate Object
        if (keysDown[kVK_ANSI_Keypad8]) {
            camera.translateY(cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        }// 0.5; //down

        if (keysDown[kVK_ANSI_Keypad5]) {
            camera.translateY(-cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        }// 0.5; //up

        if (keysDown[kVK_ANSI_Keypad4]) {
            camera.translateX(cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        }// 0.5; //Rotate left

        if (keysDown[kVK_ANSI_Keypad6]) {
            camera.translateX(-cameraIncrement);
            camera.printCameraInfo();
            debugInfo();
        }// 0.5; //Rotate right


        if (keysDown[kVK_ANSI_Keypad7]) {
            camera.rotate(vec3(cameraIncrement));
            camera.printCameraInfo();
            debugInfo();
        }// 0.5; //right

        if (keysDown[kVK_ANSI_Keypad9]) {
            camera.rotate(vec3(-cameraIncrement));
            camera.printCameraInfo();
            debugInfo();
        }// 0.5; //left

        if (keysDown[kVK_ANSI_Keypad1]) {
            camera.translate(vec3(cameraIncrement));
            camera.printCameraInfo();
            debugInfo();
        }  // + Zoom)

        if (keysDown[kVK_ANSI_Keypad3]) {
            camera.translate(vec3(-cameraIncrement));
            camera.printCameraInfo();
            debugInfo();
        } // - Zoom

        if (keysDown[kVK_ANSI_KeypadPlus]) {
            xyzIncrement += 0.05;
        }

        if (keysDown[kVK_ANSI_KeypadMinus]) {
            xyzIncrement -= 0.05;
            if (xyzIncrement < 0.0)
                xyzIncrement = 0.05;
        }

        if (keysDown[kVK_Space]) {
            debugInfo();
            camera.printCameraInfo();

            rX = -84.00;
            rY = 2.50;
            rZ = -79.50;
            camera.resetVectors();
            camera.posVec = vec3(0.0, 0.0, 2.0);

            brainOpacity = 1.00;
            [opacitySlider setDoubleValue:brainOpacity];

            timePerc = 0.00;
            [timeSlider setDoubleValue:timePerc];

            debugInfo();
            camera.printCameraInfo();
        }

        if (keysDown[kVK_ANSI_B]) {
            printf("Toggle STEREO! Was %d\n", USE_STEREO);
            USE_STEREO = !USE_STEREO;
            printf("Toggle STEREO! Now %d\n", USE_STEREO);
            // if (!USE_STEREO) USE_STEREO = true;
            // else USE_STEREO = false;
        }
    }

    void toggleDrawer() {
        if (([drawerLeftSide state] == NSDrawerOpenState)) {
            [drawerLeftSide close];
            printf("Closing Left drawer..\n");
        } else if (([drawerLeftSide state] == NSDrawerClosedState)) {
            [drawerLeftSide open];
            printf("Opening Left drawer..\n");
        }
    }

    void toggleTime1() {
        if (!c1_on) {
            c1_on = true;
            clusterColors[0].a = 1.00;
        } else {
            c1_on = false;
            clusterColors[0].a = 0.00;
        }
        printf("In toggleTime1, c1_on %d\n", c1_on);
    }

    void toggleTime2() {
        if (!c2_on) {
            c2_on = true;
            clusterColors[1].a = 1.00;
        } else {
            c2_on = false;
            clusterColors[1].a = 0.00;
        }
        printf("In toggleTime2, c2_on %d\n", c2_on);
    }

    void toggleTime3() {
        if (!c3_on) {
            c3_on = true;
            clusterColors[2].a = 1.00;
        } else {
            c3_on = false;
            clusterColors[2].a = 0.00;
        }
        printf("In toggleTime3, c3_on %d\n", c3_on);
    }

    void toggleTime4() {
        if (!c4_on) {
            c4_on = true;
            clusterColors[3].a = 1.00;
        } else {
            c4_on = false;
            clusterColors[3].a = 0.00;
        }
        printf("In toggleTime4, c4_on %d\n", c4_on);
    }



    void adjustOpacity() {
        printf("In adjustOpacity, slider is == %f\n", [opacitySlider floatValue]);
        brainOpacity = [opacitySlider floatValue];
        [opacitySlider setDoubleValue:brainOpacity];
    }


    void adjustTime() {
        printf("In adjustTime, slider is == %f\n", [timeSlider floatValue]);
        timePerc = [timeSlider floatValue];
        [timeSlider setDoubleValue:timePerc];
    }


    void initializeViews() {
        // This was a really helpful resource
        // http://stackoverflow.com/questions/349927/programmatically-creating-controls-in-cocoa
        // http://stackoverflow.com/questions/717442/how-do-i-create-cocoa-interfaces-without-interface-builder

        NSView *glv = makeGLView(400, 300);
        ActionProxy *proxy = [[ActionProxy alloc] init:[NSValue valueWithPointer:this]];

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        id appName = @"ICA+Brain View";

        // Set up the window to hold the CocoaGL view
        id window = [CocoaGL setUpAppWindow:appName
                                          x:100
                                          y:100
                                          w:800
                                          h:700];

        [CocoaGL setUpMenuBar:(CocoaGL *) glv name:appName];

        // need to look into how to autoresize the window, until then its not useful to use a regular view,
        // we are stuck with NSSplitView
        // *parentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        // setContentView:parentView];
        NSSplitView *parentView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        [parentView setVertical:YES];
        [window setContentView:parentView];

        NSView *viewDrawerLeft = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 360)];  // This is a view for the drawer
        drawerLeftSide = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200.0, 150.0) preferredEdge:NSMinXEdge];  // Now if only I could get the drawer on the left side...
        [drawerLeftSide setContentView:viewDrawerLeft];
        [drawerLeftSide setParentWindow:window];
        [drawerLeftSide open];

        /*
          Making Check boxes to control which comps I see
          For the sake a brevity, Im only going to comment one button as they all do essentially the same thing
        */

        // Setting up the button to toggle time 1
        NSButton *buttonToggleTime1 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 210, 90, 40)];  // Instantiate it, and describe its size and location
        buttonToggleTime1.bezelStyle = NSRoundedBezelStyle;     // sets the bezelStyle
        [buttonToggleTime1 setButtonType:NSSwitchButton];      // sets the button Type, I wanted a SwitchButton
        [buttonToggleTime1 setTitle:@"Comp 4"];  // Good to know, I can call @"SomeString" and it will cast it as NSString
        [buttonToggleTime1 setTarget:proxy];        // link it to ActionProxy
        [buttonToggleTime1 setState:NSOnState];     // I want the button to be 'On' when it is displaying a color
        [buttonToggleTime1 setAction:@selector(toggleTime1:)];      // link the method
        [viewDrawerLeft addSubview:buttonToggleTime1];  //  add it to the drawer view

        // Setting up the button to toggle time 2
        NSButton *buttonToggleTime2 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 180, 90, 40)];
        buttonToggleTime2.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime2 setButtonType:NSSwitchButton];
        [buttonToggleTime2 setTitle:@"Comp 11"];
        [buttonToggleTime2 setTarget:proxy];
        [buttonToggleTime2 setState:NSOnState];
        [buttonToggleTime2 setAction:@selector(toggleTime2:)];
        [viewDrawerLeft addSubview:buttonToggleTime2]; // [viewMain addSubview:buttonToggleTime2];

        // Setting up the button to toggle time 2
        NSButton *buttonToggleTime3 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 150, 90, 40)];
        buttonToggleTime3.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime3 setButtonType:NSSwitchButton];
        [buttonToggleTime3 setTitle:@"Comp 12"];
        [buttonToggleTime3 setTarget:proxy];
        [buttonToggleTime3 setState:NSOnState];
        [buttonToggleTime3 setAction:@selector(toggleTime3:)];
        [viewDrawerLeft addSubview:buttonToggleTime3]; // [viewMain addSubview:buttonToggleTime2];

        // Setting up the button to toggle time 2
        NSButton *buttonToggleTime4 = [[NSButton alloc] initWithFrame:NSMakeRect(10, 120, 90, 40)];
        buttonToggleTime4.bezelStyle = NSRoundedBezelStyle;
        [buttonToggleTime4 setButtonType:NSSwitchButton];
        [buttonToggleTime4 setTitle:@"Comp 18"];
        [buttonToggleTime4 setTarget:proxy];
        [buttonToggleTime4 setState:NSOnState];
        [buttonToggleTime4 setAction:@selector(toggleTime4:)];
        [viewDrawerLeft addSubview:buttonToggleTime4]; // [viewMain addSubview:buttonToggleTime2];

        // Setting up the Opacity slider
        opacitySlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 30, 190, 40)];
        [opacitySlider setMinValue:0.0];
        [opacitySlider setMaxValue:1.0];
        [opacitySlider setTarget:proxy];
        [opacitySlider setTitle:@"Adjust Brain Opacity"];
        [opacitySlider setNumberOfTickMarks:10];
        [opacitySlider setAllowsTickMarkValuesOnly:NO];
        [opacitySlider setAction:@selector(adjustOpacity:)];
        [opacitySlider setDoubleValue:100.0];  // Sets the position of the Slider!
        [viewDrawerLeft addSubview:opacitySlider];  // [viewMain addSubview:opacitySlider];


        // Setting up the Percent slider
        timeSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(10, 0, 190, 40)];
        [timeSlider setMinValue:0.0];
        [timeSlider setMaxValue:1.0];
        [timeSlider setTarget:proxy];
        [timeSlider setTitle:@"Adjust Time Position"];
        [timeSlider setNumberOfTickMarks:4];
        [timeSlider setAllowsTickMarkValuesOnly:NO];
        [timeSlider setAction:@selector(adjustTime:)];
        [timeSlider setDoubleValue:0.0];  // Sets the position of the Slider!
        [viewDrawerLeft addSubview:timeSlider];  // [viewMain addSubview:timeSlider];
        [[window contentView] addSubview:glv];

        [NSApp activateIgnoringOtherApps:YES]; //brings application to front on startup
        [NSApp run];

        [proxy release];
        [parentView release];
        [viewDrawerLeft release];
        [buttonToggleTime1 release];
        [buttonToggleTime2 release];
        [buttonToggleTime3 release];
        [buttonToggleTime4 release];
    }

    void debugInfo(){

        printf("\n========================= Local ===========================\n");

        printf("\t        Rx: %f, %f, %f, %f \n",Rx[0].x,Rx[0].y,Rx[0].z,Rx[0].a);
        printf("\t            %f, %f, %f, %f \n",Rx[1].x,Rx[1].y,Rx[1].z,Rx[1].a);
        printf("\t            %f, %f, %f, %f \n",Rx[2].x,Rx[2].y,Rx[2].z,Rx[2].a);
        printf("\t            %f, %f, %f, %f \n\n",Rx[3].x,Rx[3].y,Rx[3].z,Rx[3].a);

        printf("\t        Ry: %f, %f, %f, %f \n",Ry[0].x,Ry[0].y,Ry[0].z,Ry[0].a);
        printf("\t            %f, %f, %f, %f \n",Ry[1].x,Ry[1].y,Ry[1].z,Ry[1].a);
        printf("\t            %f, %f, %f, %f \n",Ry[2].x,Ry[2].y,Ry[2].z,Ry[2].a);
        printf("\t            %f, %f, %f, %f \n\n",Ry[3].x,Ry[3].y,Ry[3].z,Ry[3].a);

        printf("\t         M: %f, %f, %f, %f \n",M[0].x,M[0].y,M[0].z,M[0].a);
        printf("\t            %f, %f, %f, %f \n",M[1].x,M[1].y,M[1].z,M[1].a);
        printf("\t            %f, %f, %f, %f \n",M[2].x,M[2].y,M[2].z,M[2].a);
        printf("\t            %f, %f, %f, %f \n\n",M[3].x,M[3].y,M[3].z,M[3].a);

        printf("\t        MV: %f, %f, %f, %f \n",MV[0].x,MV[0].y,MV[0].z,MV[0].a);
        printf("\t            %f, %f, %f, %f \n",MV[1].x,MV[1].y,MV[1].z,MV[1].a);
        printf("\t            %f, %f, %f, %f \n",MV[2].x,MV[2].y,MV[2].z,MV[2].a);
        printf("\t            %f, %f, %f, %f \n\n",MV[3].x,MV[3].y,MV[3].z,MV[3].a);

        printf("\t       MVP: %f, %f, %f, %f \n",MVP[0].x,MVP[0].y,MVP[0].z,MVP[0].a);
        printf("\t            %f, %f, %f, %f \n",MVP[1].x,MVP[1].y,MVP[1].z,MVP[1].a);
        printf("\t            %f, %f, %f, %f \n",MVP[2].x,MVP[2].y,MVP[2].z,MVP[2].a);
        printf("\t            %f, %f, %f, %f \n\n",MVP[3].x,MVP[3].y,MVP[3].z,MVP[3].a);

        printf("\t  xyzIncrement: %f\n", xyzIncrement);
        printf("\t  camPos: %f, %f, %f \n", camPos.x, camPos.y, camPos.z);
        printf("\t  rX: %f, rY: %f, rZ: %f\n", rX, rY, rZ);
    }

};


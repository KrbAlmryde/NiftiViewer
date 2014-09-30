//
// Created by Kyle Almryde on 3/30/14.
// Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#include "NiftiImage.h"
//#include "Includes.hpp"
//#include "FBO.hpp"
//#include "Camera.hpp"
//#include "Program.hpp"
//#include "MeshUtils.hpp"
//#include "MeshBuffer.hpp"

#define GL_CHECK_ERRORS assert(glGetError()== GL_NO_ERROR);
using namespace std;

class DualDepthPeel : public RendererOSX {

public:
    const float MAX_DEPTH = 1.0f;

    //set screen dimensions
    const int WIDTH  = 1280;
    const int HEIGHT = 960;

    //camera transform variables
    int state = 0, oldX=0, oldY=0;
    float rX=0, rY=300, dist = -10;

    //modelview projection and rotation matrices
    glm::mat4 MV,P,R;

    //constants for box colours
    glm::vec4 box_colors[3]={glm::vec4(1.000, 0.000, 1.000,0.25),
            glm::vec4(0.000, 0.980, 0.604, 0.5),
            glm::vec4(0.000, 0.000, 0.502,0.75)
    };

    //auto rotate angle
    float angle = 0;

    //dual depth peeling FBO id
    GLuint dualDepthFBOID;
    //back texture colour attachment IDs
    GLuint backTexID[2];
    //front texture colour attachment IDs
    GLuint texID[2];
    //back texture depth attachment IDs
    GLuint depthTexID[2];
    //colour blending FBO ID
    GLuint colorBlenderFBOID;
    //colour blend FBO colour attachment texture ID
    GLuint colorBlenderTexID;

    //occlusion query ID
    GLuint queryId;

    //fullscreen quad vao and vbos
    GLuint quadVAOID;
    GLuint quadVBOID;
    GLuint quadIndicesID;

    //cube vertex array and vertex buffer object IDs
    GLuint cubeVBOID;
    GLuint cubeVAOID;
    GLuint cubeIndicesID;

    //shaders for cube, initialization, dual depth peeling, blending and final rendering
    Program cubeShader, initShader, dualPeelShader, blendShader, finalShader;

    //total number of depth peeling passes
    const int NUM_PASSES=4;

    //flag to use occlusion queries
    bool bUseOQ = true;

    //flag to use dual depth peeling
    bool bShowDepthPeeling = true;

    //blending colour alpha
    float alpha=0.6f;

    //background colour
    glm::vec4 bg=glm::vec4(0,0,0,0);

    //colour attachment IDs
    GLenum attachID[2]={GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT3};

    //draw buffer attachments
    GLenum drawBuffers[7] = {GL_COLOR_ATTACHMENT0,
            GL_COLOR_ATTACHMENT1,
            GL_COLOR_ATTACHMENT2,
            GL_COLOR_ATTACHMENT3,
            GL_COLOR_ATTACHMENT4,
            GL_COLOR_ATTACHMENT5,
            GL_COLOR_ATTACHMENT6
    };

    string RESOURCES = (string)[NSHomeDirectory() UTF8String] + "/Dropbox/XCodeProjects/aluminum/osx/examples/niftiViewer/Resources/shaders/Shaders/";

    void loadProgram(Program &p, const std::string &name) {
        p.create();
        p.attach(p.loadText(name + ".vert"), GL_VERTEX_SHADER);
        glBindAttribLocation(p.id(), 0, "vertexPosition");
        p.attach(p.loadText(name + ".frag"), GL_FRAGMENT_SHADER);

        p.link();
    }

    //FBO initialization function
    void initFBO() {
        //generate dual depth FBO
        glGenFramebuffers(1, &dualDepthFBOID);
        //The FBO has 4 colour attachments
        glGenTextures (2, texID);
        glGenTextures (2, backTexID);
        //The FBO has 2 depth attachments
        glGenTextures (2, depthTexID);

        //for each attachment
        for(int i=0;i<2;i++) {
            //first initialize the depth texture
            glBindTexture(GL_TEXTURE_RECTANGLE, depthTexID[i]);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_RECTANGLE , 0, GL_RGB32F, WIDTH, HEIGHT, 0, GL_RGB, GL_FLOAT, NULL);

            GL_CHECK_ERRORS

            //initialize the colour attachment
            glBindTexture(GL_TEXTURE_RECTANGLE,texID[i]);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_RECTANGLE , 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_FLOAT, NULL);

            GL_CHECK_ERRORS

            //initialize the back colour attachment
            glBindTexture(GL_TEXTURE_RECTANGLE,backTexID[i]);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_RECTANGLE , 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_FLOAT, NULL);

            GL_CHECK_ERRORS
        }

        GL_CHECK_ERRORS


        //Now setup the colour attachment for colour blend FBO
        glGenTextures(1, &colorBlenderTexID);
        glBindTexture(GL_TEXTURE_RECTANGLE, colorBlenderTexID);
        glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_RECTANGLE, 0, GL_RGB, WIDTH, HEIGHT, 0, GL_RGB, GL_FLOAT, 0);

        GL_CHECK_ERRORS

        //generate the colour blend FBO ID
        glGenFramebuffers(1, &colorBlenderFBOID);
        glBindFramebuffer(GL_FRAMEBUFFER, colorBlenderFBOID);
        //set the colour blender texture as the FBO colour attachment
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE, colorBlenderTexID, 0);

        //bind the dual depth FBO
        glBindFramebuffer(GL_FRAMEBUFFER, dualDepthFBOID);

        GL_CHECK_ERRORS

        //bind the six colour attachments for this FBO
        for(int i=0;i<2;i++) {
            glFramebufferTexture2D(GL_FRAMEBUFFER, attachID[i], GL_TEXTURE_RECTANGLE, depthTexID[i], 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, attachID[i]+1, GL_TEXTURE_RECTANGLE, texID[i], 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, attachID[i]+2, GL_TEXTURE_RECTANGLE, backTexID[i], 0);
        }

        GL_CHECK_ERRORS

        //set the colour blender texture as the 7th attachment
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT6, GL_TEXTURE_RECTANGLE, colorBlenderTexID, 0);

        GL_CHECK_ERRORS

        //check the FBO completeness status
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if(status == GL_FRAMEBUFFER_COMPLETE )
            printf("FBO setup successful !!! \n");
        else
            printf("Problem with FBO setup\n");

        //unbind FBO
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

//delete all FBO related resources
    void shutdownFBO() {
        glDeleteFramebuffers(1, &dualDepthFBOID);
        glDeleteFramebuffers(1, &colorBlenderFBOID);
        glDeleteTextures (2, texID);
        glDeleteTextures (2, backTexID);
        glDeleteTextures (2, depthTexID);
        glDeleteTextures(1, &colorBlenderTexID);
    }

//OpenGL initialization function
    void onCreate() {

        GL_CHECK_ERRORS

        //initialize FBO
        initFBO();

        printf("Trying to load Programs\n");
        //Load the cube shader
        loadProgram(cubeShader, RESOURCES + "cube_shader");

        GL_CHECK_ERRORS

        //Load the initialization shader
        loadProgram(initShader, RESOURCES + "dual_init");

        GL_CHECK_ERRORS

        //Load the dual depth peeling shader
        loadProgram(dualPeelShader, RESOURCES + "dual_peel");

        //pass constant uniforms at initialization
        dualPeelShader.bind();
            glUniform1i(dualPeelShader.uniform("depthBlenderTex"), 0);
            glUniform1i(dualPeelShader.uniform("frontBlenderTex"), 1);
        dualPeelShader.unbind();

        GL_CHECK_ERRORS

        //Load the blending shader
        loadProgram(blendShader, RESOURCES + "blend");
        //pass constant uniforms at initialization
        blendShader.bind();
            glUniform1i(blendShader.uniform("tempTexture"), 0);
        blendShader.unbind();

        GL_CHECK_ERRORS

        //Load the final shader
        loadProgram(finalShader, RESOURCES + "final");
        //pass constant uniforms at initialization
        finalShader.bind();
            glUniform1i(finalShader.uniform("depthBlenderTex"), 0);
            glUniform1i(finalShader.uniform("frontBlenderTex"), 1);
            glUniform1i(finalShader.uniform("backBlenderTex"), 2);
        finalShader.unbind();


        //generate hardwre query
        glGenQueries(1, &queryId);

        GL_CHECK_ERRORS

        //generate the quad vertices
        glm::vec2 quadVerts[4];
        quadVerts[0] = glm::vec2(0,0);
        quadVerts[1] = glm::vec2(1,0);
        quadVerts[2] = glm::vec2(1,1);
        quadVerts[3] = glm::vec2(0,1);

        //generate quad indices
        GLushort quadIndices[]={ 0,1,2,0,2,3};

        //generate quad  vertex array and vertex buffer objects
        glGenVertexArrays(1, &quadVAOID);
        glGenBuffers(1, &quadVBOID);
        glGenBuffers(1, &quadIndicesID);

        glBindVertexArray(quadVAOID);
            glBindBuffer (GL_ARRAY_BUFFER, quadVBOID);
            //pass quad vertices to buffer object memory
            glBufferData (GL_ARRAY_BUFFER, sizeof(quadVerts), &quadVerts[0], GL_STATIC_DRAW);

            GL_CHECK_ERRORS

            //enable vertex attribute array for position
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE,0,0);

            //pass the quad indices to the element array buffer
            glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, quadIndicesID);
            glBufferData (GL_ELEMENT_ARRAY_BUFFER, sizeof(quadIndices), &quadIndices[0], GL_STATIC_DRAW);

        //setup unit cube vertex array and vertex buffer objects
        glGenVertexArrays(1, &cubeVAOID);
        glGenBuffers(1, &cubeVBOID);
        glGenBuffers(1, &cubeIndicesID);

        //unit cube vertices
        glm::vec3 vertices[8]={	glm::vec3(-0.5f,-0.5f,-0.5f),
                glm::vec3( 0.5f,-0.5f,-0.5f),
                glm::vec3( 0.5f, 0.5f,-0.5f),
                glm::vec3(-0.5f, 0.5f,-0.5f),
                glm::vec3(-0.5f,-0.5f, 0.5f),
                glm::vec3( 0.5f,-0.5f, 0.5f),
                glm::vec3( 0.5f, 0.5f, 0.5f),
                glm::vec3(-0.5f, 0.5f, 0.5f)};

        //unit cube indices
        GLushort cubeIndices[36]={0,5,4,
                5,0,1,
                3,7,6,
                3,6,2,
                7,4,6,
                6,4,5,
                2,1,3,
                3,1,0,
                3,0,7,
                7,0,4,
                6,5,2,
                2,5,1};
        glBindVertexArray(cubeVAOID);
            glBindBuffer (GL_ARRAY_BUFFER, cubeVBOID);
            //pass cube vertices to buffer object memory
            glBufferData (GL_ARRAY_BUFFER, sizeof(vertices), &(vertices[0].x), GL_STATIC_DRAW);

            GL_CHECK_ERRORS

            //enable vertex attributre array for position
            glEnableVertexAttribArray(0);
            glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE,0,0);

            //pass cube indices to element array  buffer
            glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, cubeIndicesID);
            glBufferData (GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeIndices), &cubeIndices[0], GL_STATIC_DRAW);

        glBindVertexArray(0);


        cout<<"Initialization successfull"<<endl;
    }

//release all allocated resources
    void OnShutdown() {
        cubeShader.destroy();
        initShader.destroy();
        dualPeelShader.destroy();
        blendShader.destroy();
        finalShader.destroy();

        shutdownFBO();
        glDeleteQueries(1, &queryId);

        glDeleteVertexArrays(1, &quadVAOID);
        glDeleteBuffers(1, &quadVBOID);
        glDeleteBuffers(1, &quadIndicesID);

        glDeleteVertexArrays(1, &cubeVAOID);
        glDeleteBuffers(1, &cubeVBOID);
        glDeleteBuffers(1, &cubeIndicesID);


        cout<<"Shutdown successfull"<<endl;
    }

    //resize event handler
    void onReshape() {
        //set the viewport
        glViewport (0, 0, (GLsizei) 1280, (GLsizei) 960);
        //setup the projection matrix
        P = glm::perspective(60.0f,(float)1280/960, 0.1f,1000.0f);
    }



//idle callback
    void OnIdle() {
        //create a new rotation matrix for rotation on the Y axis
        R = glm::rotate(glm::mat4(1), glm::radians(angle+=5), glm::vec3(0,1,0));
        //recall the display callback
    }

//function to render scene given the combined modelview projection matrix
//and a shader
    void DrawScene(const glm::mat4& MVP, Program& shader, bool useColor=false, bool useAlphaMultiplier=false) {
        //enable alpha blending with over compositing
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        //bind the cube vertex array object
        glBindVertexArray(cubeVAOID);

        //bind the shader
        shader.bind();
            //for all cubes
            for(int k=-1;k<=1;k++) {
                for(int j=-1;j<=1;j++) {
                    int index =0;
                    for(int i=-1;i<=1;i++) {
    //                    GL_CHECK_ERRORS
                        //set the modelling transformation and shader uniforms
                        glm::mat4 T = glm::translate(glm::mat4(1), glm::vec3(i*2,j*2,k*2));
                        if(useColor)
                            glUniform4fv(shader.uniform("vColor"),1, &(box_colors[index++].x));
                        if(useAlphaMultiplier)
                            glUniform1f(shader.uniform("alpha"), alpha);

                        glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP*R*T));

                        //draw the cube
                        glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);
//                        GL_CHECK_ERRORS
                    }
                }
            }
        //unbind shader
        shader.unbind();
        //unbind vertex array object
        glBindVertexArray(0);
        //diable alpha blending
        glDisable(GL_BLEND);
    }

//function to draw a fullscreen quad
    void DrawFullScreenQuad() {
        //bind the quad vertex array object
        glBindVertexArray(quadVAOID);
        //draw 2 triangles
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
    }

//display callback function
    void onFrame() {

        handleMouse();
        handleKeys();

        //camera transformation
        glm::mat4 Tr	= glm::translate(glm::mat4(1.0f),glm::vec3(0.0f, 0.0f, dist));
        glm::mat4 Rx	= glm::rotate(Tr,  rX, glm::vec3(1.0f, 0.0f, 0.0f));
        glm::mat4 MV    = glm::rotate(Rx, rY, glm::vec3(0.0f, 1.0f, 0.0f));

        //clear colour and depth buffer
        glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);

        //get the combined modelview projection matrix
        glm::mat4 MVP	= P*MV;

        //if we want to use depth peeling
        if(bShowDepthPeeling) {

            //disble depth test and enable alpha blending
            glDisable(GL_DEPTH_TEST);
            glEnable(GL_BLEND);

            //bind dual depth FBO
            glBindFramebuffer(GL_FRAMEBUFFER, dualDepthFBOID);

            // Render targets 1 and 2 store the front and back colors
            // Clear to 0.0 and use MAX blending to filter written color
            // At most one front color and one back color can be written every pass
            glDrawBuffers(2, &drawBuffers[1]);
            glClearColor(0, 0, 0, 0);
            glClear(GL_COLOR_BUFFER_BIT);


            // Render target 0 stores (-minDepth, maxDepth)
            glDrawBuffer(drawBuffers[0]);
            //clear the offscreen texture with -MAX_DEPTH
            glClearColor(-MAX_DEPTH, -MAX_DEPTH, 0, 0);
            glClear(GL_COLOR_BUFFER_BIT);
            //enable max blending
            glBlendEquation(GL_MAX);
            //render scene with the initialization shader
            DrawScene(MVP, initShader);

            // 2. Depth peeling + blending pass
            glDrawBuffer(drawBuffers[6]);
            //clear color buffer with the background colour
            glClearColor(bg.x, bg.y, bg.z, 0);
            glClear(GL_COLOR_BUFFER_BIT);

            int currId = 0;
            //for each pass
            for (int layer = 1; bUseOQ || layer < NUM_PASSES; layer++) {
                currId = layer % 2;
                int prevId = 1 - currId;
                int bufId = currId * 3;

                //render to 2 colour attachments simultaneously
                glDrawBuffers(2, &drawBuffers[bufId+1]);
                //set clear color to black and clear colour buffer
                glClearColor(0, 0, 0, 0);
                glClear(GL_COLOR_BUFFER_BIT);

                //alternate the colour attachment for draw buffer
                glDrawBuffer(drawBuffers[bufId+0]);
                //clear the color to -MAX_DEPTH and clear colour buffer
                glClearColor(-MAX_DEPTH, -MAX_DEPTH, 0, 0);
                glClear(GL_COLOR_BUFFER_BIT);

                //Render to three draw buffers simultaneously
                // Render target 0: RG32F MAX blending
                // Render target 1: RGBA MAX blending
                // Render target 2: RGBA MAX blending
                glDrawBuffers(3, &drawBuffers[bufId+0]);
                //enable max blending
                glBlendEquation(GL_MAX);

                //bind depth texture to texture unit 0
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_RECTANGLE, depthTexID[prevId]);

                //bind colour attachment texture to texture unit 1
                glActiveTexture(GL_TEXTURE1);
                glBindTexture(GL_TEXTURE_RECTANGLE, texID[prevId]);

                //draw scene using the dual peel shader
                DrawScene(MVP, dualPeelShader, true,true);

                // Full screen pass to alpha-blend the back color
                glDrawBuffer(drawBuffers[6]);

                //set the over blending
                glBlendEquation(GL_FUNC_ADD);
                glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

                //if we want to use occlusion query, we initiate it
                if (bUseOQ) {
                    glBeginQuery(GL_SAMPLES_PASSED, queryId);
                }

                GL_CHECK_ERRORS

                //bind the back colour attachment to texture unit 0
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_RECTANGLE, backTexID[currId]);

                //use blending shader and draw a fullscreen quad
                blendShader.bind();
                    DrawFullScreenQuad();
                blendShader.unbind();

                //if we initiated the occlusion query, we end it and get
                //the query result which is the total number of samples
                //output from the blending result
                if (bUseOQ) {
                    glEndQuery(GL_SAMPLES_PASSED);
                    GLuint sample_count;
                    glGetQueryObjectuiv(queryId, GL_QUERY_RESULT, &sample_count);
                    if (sample_count == 0) {
                        break;
                    }
                }
                GL_CHECK_ERRORS
            }

//            GL_CHECK_ERRORS

            //disable alpha blending
            glDisable(GL_BLEND);

            // 3. Final render pass
            //remove the FBO
            glBindFramebuffer(GL_FRAMEBUFFER, 0);
            //restore the default back buffer
            glDrawBuffer(GL_BACK_LEFT);

            //bind the depth texture to texture unit 0
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_RECTANGLE, depthTexID[currId]);

            //bind the depth texture to colour texture to texture unit 1
            glActiveTexture(GL_TEXTURE1);
            glBindTexture(GL_TEXTURE_RECTANGLE, texID[currId]);

            //bind the colour blender texture to texture unit 2
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_RECTANGLE, colorBlenderTexID);

            //bind the final shader and draw a fullscreen quad
            finalShader.bind();
                DrawFullScreenQuad();
            finalShader.unbind();

        } else {
            //no depth peeling, render scene with default alpha blending
            glEnable(GL_DEPTH_TEST);
            DrawScene(MVP, cubeShader, true,false);
        }

    }

//mouse down event handler
    void handleKeys() {
        if (keysDown[kVK_Space]) {
            bShowDepthPeeling = !bShowDepthPeeling;
        }

        if(bShowDepthPeeling) {
            printf("Dual Depth Peeling: On\n");
        } else {
            printf("Dual Depth Peeling: Off\n");
        }
    }


//mouse move event handler
    void handleMouse() {

        bool movingLeft = false;
        bool movingRight = false;
        bool movingUp = false;
        bool movingDown = false;

        if (state == 0) {
            dist += (mouseY - previousMouseY)/5.0f;
        } else {
            rX += (mouseY - previousMouseY)/5.0f;
            rY += (mouseX - previousMouseX)/5.0f;
        }
        previousMouseX = mouseX;
        previousMouseY = mouseY;


        if (mouseX < previousMouseX) {
            movingLeft = true;
        } else if (mouseX > previousMouseX) {
            movingRight = true;
        }

        if (mouseY < previousMouseY) {
            movingUp = true;
        } else if (mouseY > previousMouseY) {
            movingDown = true;
        }

        if(isDragging) {
            state = 0;
        } else {
            state = 1;
        }

        if (isMoving) {
            isMoving = false; //isn't there a listener that can hear when a mouse *stops*?
        }


    }

    void initializeViews() {
        // This was a really helpful resource
        // http://stackoverflow.com/questions/349927/programmatically-creating-controls-in-cocoa
        // http://stackoverflow.com/questions/717442/how-do-i-create-cocoa-interfaces-without-interface-builder

        NSView *glv = makeGLView(1280, 960);

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        id appName = @"Dual Depth Peeling Demo";

        // Set up the window to hold the CocoaGL view
        id window = [CocoaGL setUpAppWindow:appName
                                          x:100
                                          y:100
                                          w:1280
                                          h:960];

        [CocoaGL setUpMenuBar:(CocoaGL *) glv name:appName];

        // need to look into how to autoresize the window, until then its not useful to use a regular view,
        NSSplitView *parentView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        [parentView setVertical:YES];
        [window setContentView:parentView];

        [[window contentView] addSubview:glv];
        [NSApp activateIgnoringOtherApps:YES]; //brings application to front on startup
        [NSApp run];

        [parentView release];

        //output hardware information
        cout<<"\tVendor: "<<glGetString (GL_VENDOR)<<endl;
        cout<<"\tRenderer: "<<glGetString (GL_RENDERER)<<endl;
        cout<<"\tVersion: "<<glGetString (GL_VERSION)<<endl;
        cout<<"\tGLSL: "<<glGetString (GL_SHADING_LANGUAGE_VERSION)<<endl;

    }

};
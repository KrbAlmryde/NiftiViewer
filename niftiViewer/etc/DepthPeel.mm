//
// Created by Kyle Almryde on 3/28/14.
// Copyright (c) 2014 Angus Forbes. All rights reserved.
//

//#include "Includes.hpp"
//#include "FBO.hpp"
#include "NiftiImage.h"
//#include "Camera.hpp"
//#include "Program.hpp"
//#include "MeshUtils.hpp"
//#include "MeshBuffer.hpp"

#define GL_CHECK_ERRORS assert(glGetError()== GL_NO_ERROR);
using namespace std;

class DepthPeel : public RendererOSX {

public:

    //set screen dimensions
    const int WIDTH  = 1280;
    const int HEIGHT = 960;

    //camera transform variables
    int state = 0, oldX=0, oldY=0;
    float rX=0, rY=300, dist = -10;

    //modelview projection and rotation matrices
    glm::mat4 MV,P,R;

    //constants for box colours
    glm::vec4 box_colors[3]={glm::vec4(1,0,0,0.5),
            glm::vec4(0,1,0,0.5),
            glm::vec4(0,0,1,0.5)
    };

    //auto rotate angle
    float angle = 0;

    //FBO id
    GLuint fbo[2];
    //FBO colour attachment IDs
    GLuint texID[2];
    //FBO depth attachment IDs
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


    //shaders for cube, front to back peeling, blending and final rendering
    Program cubeShader, frontPeelShader, blendShader, finalShader;

    //total number of depth peeling passes
    const int NUM_PASSES=6;

    //flag to use occlusion queries
    bool bUseOQ = true;

    //flag to use depth peeling
    bool bShowDepthPeeling = true;

    //background colour
    glm::vec4 bg=glm::vec4(0,0,0,0);

    string RESOURCES = (string)[NSHomeDirectory() UTF8String] + "/Dropbox/XCodeProjects/aluminum/osx/examples/niftiViewer/Resources/shaders/Shaders/";


    void loadProgram(Program &p, const std::string &name) {

        p.create();
        p.attach(p.loadText(name + ".vsh"), GL_VERTEX_SHADER);
        glBindAttribLocation(p.id(), 0, "vertexPosition");
        p.attach(p.loadText(name + ".fsh"), GL_FRAGMENT_SHADER);

        p.link();
    }

    //FBO initialization function
    void initFBO() {
        //generate 2 FBO
        glGenFramebuffers(2, fbo);
        //The FBO has two colour attachments
        glGenTextures (2, texID);
        //The FBO has two depth attachments
        glGenTextures (2, depthTexID);

        //for each attachment
        for(int i=0;i<2;i++) {
            //first initialize the depth texture
            glBindTexture(GL_TEXTURE_RECTANGLE, depthTexID[i]);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_RECTANGLE , 0, GL_DEPTH_COMPONENT32F, WIDTH, HEIGHT, 0, GL_DEPTH_COMPONENT, GL_FLOAT, NULL);

            GL_CHECK_ERRORS

            //second initialize the colour attachment
            glBindTexture(GL_TEXTURE_RECTANGLE,texID[i]);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_RECTANGLE , GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_RECTANGLE , 0,GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_FLOAT, NULL);

            //bind FBO and attach the depth and colour attachments
            glBindFramebuffer(GL_FRAMEBUFFER, fbo[i]);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,  GL_TEXTURE_RECTANGLE, depthTexID[i], 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE, texID[i], 0);
        }
        GL_CHECK_ERRORS

        //Now setup the colour attachment for colour blend FBO
        glGenTextures(1, &colorBlenderTexID);
        glBindTexture(GL_TEXTURE_RECTANGLE, colorBlenderTexID);
        glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_RECTANGLE, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexImage2D(GL_TEXTURE_RECTANGLE, 0, GL_RGBA, WIDTH, HEIGHT, 0, GL_RGBA, GL_FLOAT, 0);

        //generate the colour blend FBO ID
        glGenFramebuffers(1, &colorBlenderFBOID);
        glBindFramebuffer(GL_FRAMEBUFFER, colorBlenderFBOID);

        //set the depth attachment of previous FBO as depth attachment for this FBO
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_TEXTURE_RECTANGLE, depthTexID[0], 0);
        //set the colour blender texture as the FBO colour attachment
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE, colorBlenderTexID, 0);

        //check the FBO completeness status
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if(status == GL_FRAMEBUFFER_COMPLETE )
            printf("FBO setup successful !!! \n");
        else
            printf("Problem with FBO setup");

        //unbind FBO
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }


    //OpenGL initialization function
    void onCreate() {


        //initialize FBO
        initFBO();

        // load Programs
        printf("Trying to load Programs\n");
        loadProgram(cubeShader, RESOURCES+"cube_shader");
        loadProgram(frontPeelShader, RESOURCES+"front_peel");
        loadProgram(blendShader, RESOURCES+"blend");
        loadProgram(finalShader, RESOURCES+"final");

        //generate hardwre query
        glGenQueries(1, &queryId);

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

        //enable vertex attributre array for position
                glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE,0,0);

        //pass cube indices to element array  buffer
        glBindBuffer (GL_ELEMENT_ARRAY_BUFFER, cubeIndicesID);
        glBufferData (GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeIndices), &cubeIndices[0], GL_STATIC_DRAW);

        glBindVertexArray(0);
        cout<<"Initialization successfull"<<endl;
    }

    //resize event handler
    void onReshape() {
        //set the viewport
        glViewport (0, 0, (GLsizei) 1280, (GLsizei) 960);
        //setup the projection matrix
        P = glm::perspective(60.0f,(float)1280/960, 0.1f,1000.0f);
    }


    //function to render scene given the combined modelview projection matrix
    //and a shader
    void DrawScene(const glm::mat4& MVP, Program& shader) {
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
                    //set the modelling transformation and shader uniforms
                    glm::mat4 T = glm::translate(glm::mat4(1), glm::vec3(i*2,j*2,k*2));
                    glUniform4fv(shader.uniform("vColor"),1, &(box_colors[index++].x));
                    glUniformMatrix4fv(shader.uniform("MVP"), 1, GL_FALSE, glm::value_ptr(MVP*R*T));
                    //draw the cube
                    glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_SHORT, 0);
                }
            }
        }
        //unbind shader
        shader.unbind();
        //unbind vertex array object
        glBindVertexArray(0);
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
            //bind the colour blending FBO
            glBindFramebuffer(GL_FRAMEBUFFER, colorBlenderFBOID);
            //set the first colour attachment as the draw buffer
            glDrawBuffer(GL_COLOR_ATTACHMENT0);
            //clear the colour and depth buffer
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );

            // 1. In the first pass, we render normally with depth test enabled to get the nearest surface
            glEnable(GL_DEPTH_TEST);
            DrawScene(MVP, cubeShader);

            // 2. Depth peeling + blending pass
            int numLayers = (NUM_PASSES - 1) * 2;

            //for each pass
            for (int layer = 1; bUseOQ || layer < numLayers; layer++) {
                int currId = layer % 2;
                int prevId = 1 - currId;

                //bind the current FBO
                glBindFramebuffer(GL_FRAMEBUFFER, fbo[currId]);
                //set the first colour attachment as draw buffer
                glDrawBuffer(GL_COLOR_ATTACHMENT0);

                //set clear colour to black
                glClearColor(0, 0, 0, 0);
                //clear the colour and depth buffers
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

                //disbale blending and depth testing
                glDisable(GL_BLEND);
                glEnable(GL_DEPTH_TEST);

                //if we want to use occlusion query, we initiate it
                if (bUseOQ) {
                    glBeginQuery(GL_SAMPLES_PASSED, queryId);
                }

//                GL_CHECK_ERRORS

                //bind the depth texture from the previous step
                glBindTexture(GL_TEXTURE_RECTANGLE, depthTexID[prevId]);

                //render scene with the front to back peeling shader
                DrawScene(MVP, frontPeelShader);

                //if we initiated the occlusion query, we end it
                if (bUseOQ) {
                    glEndQuery(GL_SAMPLES_PASSED);
                }

//                GL_CHECK_ERRORS

                //bind the colour blender FBO
                glBindFramebuffer(GL_FRAMEBUFFER, colorBlenderFBOID);
                //render to its first colour attachment
                glDrawBuffer(GL_COLOR_ATTACHMENT0);

                //enable blending but disable depth testing
                glDisable(GL_DEPTH_TEST);
                glEnable(GL_BLEND);

                //change the blending equation to add
                glBlendEquation(GL_FUNC_ADD);
                //use separate blending function
                glBlendFuncSeparate(GL_DST_ALPHA, GL_ONE,
                        GL_ZERO, GL_ONE_MINUS_SRC_ALPHA);

                //bind the result from the previous iteration as texture
                glBindTexture(GL_TEXTURE_RECTANGLE, texID[currId]);

                //bind the blend shader and then draw a fullscreen quad
                blendShader.bind();
                    DrawFullScreenQuad();
                blendShader.unbind();

                //disable blending
                glDisable(GL_BLEND);

//                GL_CHECK_ERRORS

                //if we initiated the occlusion query, we get the query result
                //that is the total number of samples
                if (bUseOQ) {
                    GLuint sample_count;
                    glGetQueryObjectuiv(queryId, GL_QUERY_RESULT, &sample_count);
                    if (sample_count == 0) {
                        break;
                    }
                }
            }

//            GL_CHECK_ERRORS

            // 3. Final render pass
            //remove the FBO
                    glBindFramebuffer(GL_FRAMEBUFFER, 0);
            //restore the default back buffer
            glDrawBuffer(GL_BACK_LEFT);
            //disable depth testing and blending
            glDisable(GL_DEPTH_TEST);
            glDisable(GL_BLEND);

            //bind the colour blender texture
            glBindTexture(GL_TEXTURE_RECTANGLE, colorBlenderTexID);
            //bind the final shader

            finalShader.bind();
                //set shader uniforms
                glUniform4fv(finalShader.uniform("vBackgroundColor"), 1, &bg.x);
                //draw full screen quad
                DrawFullScreenQuad();
            finalShader.unbind();

        } else {
            //no depth peeling, render scene with default alpha blending
            glEnable(GL_DEPTH_TEST);
            DrawScene(MVP, cubeShader);
        }
    }

    void handleKeys() {
        if (keysDown[kVK_Space]) {
            bShowDepthPeeling = !bShowDepthPeeling;
        }

        if(bShowDepthPeeling) {
            printf("Front-to-back Depth Peeling: On\n");
        } else {
            printf("Front-to-back Depth Peeling: Off\n");
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

        id appName = @"Fron-to-back Depth Peeling Demo";

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
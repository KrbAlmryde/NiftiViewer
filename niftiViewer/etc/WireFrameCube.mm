//
// Created by Kyle Almryde on 11/15/13.
// Copyright (c) 2013 Angus Forbes. All rights reserved.
//

#define BUFFER_OFFSET(i) (reinterpret_cast<void*>(i))

using namespace aluminum;

class WireFrameCube : public RendererOSX {

public:

    // Set Global vars
    bool USE_STEREO = false;
    string RESOURCES = (string)
    [

    NSHomeDirectory()

    UTF8String] + "/Dropbox/XCodeProjects/aluminum/osx/examples/niftiViewer-KrbA/resources/";

    Texture brain;
    Camera camera;
    Program program;

    MeshData meshData;
    MeshBuffer meshBuffer;

    mat4 textureRotation, textureRotationStart, view, proj;

    GLint posLoc = 0;
    GLint texCoordLoc = 1;


    const int XDIM = 91;
    const int YDIM = 109;
    const int ZDIM = 91;


    /******************************************************************
     * wrapper for Texture::loadTexture
     ******************************************************************/
    void loadTexture(Texture &t, const std::string &name) {
        printf("\n\tIn loadTexture\n");
        t.loadTexture(t, name);
    } // end of loadTexture


    /*******************************************************************
     * Creates a Program object, then links the attached shaders to that
     * object. This in effect prepares our shaders
     *******************************************************************/
    void loadProgram(Program &p, const std::string &name) {
        printf("\n\tIn loadProgram!\n");

        p.create();  // This creates an 'empty' Program object

        // This attaches a shader object to the Program object
        //  p.loadText is doing what it sounds like...
        p.attach(p.loadText(name + ".vsh"), GL_VERTEX_SHADER);

        // This is effectively binding a named attribute variable ("vertexPosition"), with
        // a generic attribute index (posLoc)
        //VVVV--p.id() returns a GLuint! Its basically the Program objects ID number
        glBindAttribLocation(p.id(), (GLuint) posLoc, "vertexPosition");
        glBindAttribLocation(p.id(), texCoordLoc, "vertexTexCoord");


        p.attach(p.loadText(name + ".fsh"), GL_FRAGMENT_SHADER);


        // This is effectively linking the Program object to the attached Shader Objects
        // thereby creating shader executables which will then be run by the GPU
        // Additionally, it maps uniforms and attributes to their Program id
        p.link();

    } // end of loadProgram


    /******************************************************
     *  Loads available nifti images into 3D textures,
     *  then builds a texture
     ******************************************************/
    void onCreate() {
        printf("\n\tIn onCreate!\n");

        loadProgram(program, RESOURCES + "wireFrame");

        camera = Camera(60.0, width / (height * 1.0), 0.001, 100.0);
        camera.resetVectors();
        camera.translateZ(-5.000000);
        /*
         *  Constructs a texture mesh of a cube which we will
         *  later pass our ray through
         */
        meshData = MeshUtils::makeWireFrameCube(1.0f);
        meshBuffer.init(meshData, posLoc, -1, texCoordLoc, -1);


        textureRotation = glm::mat4();
        textureRotationStart = glm::mat4();


        glEnable(GL_DEPTH_TEST);
        glDepthFunc(GL_LEQUAL);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_SCISSOR_TEST);

    } // end of onCreate


    void draw(mat4 useproj, mat4 useview) {
        // printf("\n\tIn draw!\n");

        program.bind();
        {

            glUniformMatrix4fv(program.uniform("proj"), 1, 0, ptr(useproj));
            glUniformMatrix4fv(program.uniform("view"), 1, 0, ptr(useview));
            glUniformMatrix4fv(program.uniform("textureRotation"), 1, 0, ptr(textureRotation));
            meshBuffer.drawLines();

        }
        program.unbind();
    } // end of void draw()


    //every 1/60th of a second...
    void onFrame() {

        // printf("\n\tIn onFrame!\n");

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
    *******************************/
    void onReshape() {
        printf("\n\tIn onReshape!\n");

        camera.perspective(60.0, (float) width / (float) height, 0.001, 100.0);
        printf("camera: %f, %f %f", camera.posVec.x, camera.posVec.y, camera.posVec.z);
    } // Angus version



    /**********************************
    *
    * Takes care of Mouse interactions
    ***********************************/
    void handleMouse() {
//        printf("\n\tIn handleMouse!\n");

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
    }

    void handleKeys_arrows() {

        float dg = 1.0f;
        if (keysDown[kVK_Shift]) {
            dg = 3.0f;
        }

        if (keysDown[kVK_UpArrow]) {
            printf("Pressing UpArrow!\n");
            camera.rotateX(dg);
        }

        if (keysDown[kVK_DownArrow]) {
            printf("Pressing DownArrow!\n");
            camera.rotateX(-dg);
        }

        if (keysDown[kVK_LeftArrow]) {
            printf("Pressing LeftArrow!\n");
            camera.rotateY(-dg);
        }

        if (keysDown[kVK_RightArrow]) {
            printf("Pressing RightArrow!\n");
            camera.rotateY(dg);
        }
    }

    void handleKeys_wasdqe() {
        float dg = 1.0f;

        if (keysDown[kVK_Shift]) {
            dg = 3.0f;
        }

        if (keysDown[kVK_ANSI_W]) {
            printf("Pressing W key!\n");
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(1.0, 0.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_S]) {
            printf("Pressing S key!\n");
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(1.0, 0.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_A]) {
            printf("Pressing A key!\n");
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(0.0, 1.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_D]) {
            printf("Pressing D key!\n");
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(0.0, 1.0, 0.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_Q]) {
            printf("Pressing Q key!\n");
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, dg, vec3(0.0, 0.0, 1.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

        if (keysDown[kVK_ANSI_E]) {
            printf("Pressing E key!\n");
            textureRotation = glm::translate(textureRotation, vec3(0.5, 0.5, 0.5));
            textureRotation = glm::rotate(textureRotation, -dg, vec3(0.0, 0.0, 1.0));
            textureRotation = glm::translate(textureRotation, vec3(-0.5, -0.5, -0.5));
        }

    }


    void handleKeys_auxilliary() {
        float amt = 0.001;
        float dg = 0.05;

        // Increase Z!  Zoom In!
        if (keysDown[kVK_ANSI_Z]) {
            camera.translateZ(dg);
        }

        // Decrease Z! Zoom Out!
        if (keysDown[kVK_ANSI_X]) {
//            amt=-0.001;
//            dg=-0.05;
            camera.translateZ(-dg);
        }


        // Take us home!
        if (keysDown[kVK_ANSI_KeypadEnter]) {
            printf("\nReset layout!\n");
            printf("\nBefore textureReset...\n");
            std::cout << "\tTranslation: " << glm::to_string(textureRotation) << "\n";
            std::cout << "\t Rotatation: " << glm::to_string(textureRotation) << "\n";
            std::cout << "\tTranslation: " << glm::to_string(textureRotation) << "\n\n";

            std::cout << "\tposVec:  " << glm::to_string(camera.posVec) << "\n";
            std::cout << "\tviewVec: " << glm::to_string(camera.viewVec) << "\n";
            std::cout << "\t\tlBView:  " << glm::to_string(camera.leftBackView) << "\n";
            std::cout << "\t\trBView:  " << glm::to_string(camera.rightBackView) << "\n";
            std::cout << "\t\trtView:  " << glm::to_string(camera.rightView) << "\n";
            std::cout << "\t\tltView:  " << glm::to_string(camera.leftView) << "\n\n";

            std::cout << "\tupVec:   " << glm::to_string(camera.upVec) << "\n";
            std::cout << "\trtVec:   " << glm::to_string(camera.rightVec) << "\n\n";

            std::cout << "\t\tproject: " << glm::to_string(camera.projection) << "\n";
            std::cout << "\t\tLproj:   " << glm::to_string(camera.leftProjection) << "\n";
            std::cout << "\t\tRproj:   " << glm::to_string(camera.rightProjection) << "\n\n";


            std::cout << "\t\tLTran:   " << glm::to_string(camera.leftTranslate) << "\n\n";
            std::cout << "\t\tRTran:   " << glm::to_string(camera.rightTranslate) << "\n\n";


            textureRotation = textureRotationStart;
            camera.resetVectors();
            camera.translateZ(-5.000000);

            printf("\nAfter textureReset...\n");
            std::cout << "\tTranslation: " << glm::to_string(textureRotation) << "\n";
            std::cout << "\t Rotatation: " << glm::to_string(textureRotation) << "\n";
            std::cout << "\tTranslation: " << glm::to_string(textureRotation) << "\n\n";

            std::cout << "\tposVec:  " << glm::to_string(camera.posVec) << "\n";
            std::cout << "\tviewVec: " << glm::to_string(camera.viewVec) << "\n";
            std::cout << "\t\tlBView:  " << glm::to_string(camera.leftBackView) << "\n";
            std::cout << "\t\trBView:  " << glm::to_string(camera.rightBackView) << "\n";
            std::cout << "\t\trtView:  " << glm::to_string(camera.rightView) << "\n";
            std::cout << "\t\tltView:  " << glm::to_string(camera.leftView) << "\n\n";

            std::cout << "\tupVec:   " << glm::to_string(camera.upVec) << "\n";
            std::cout << "\trtVec:   " << glm::to_string(camera.rightVec) << "\n\n";

            std::cout << "\t\tproject: " << glm::to_string(camera.projection) << "\n";
            std::cout << "\t\tLproj:   " << glm::to_string(camera.leftProjection) << "\n";
            std::cout << "\t\tRproj:   " << glm::to_string(camera.rightProjection) << "\n\n";


            std::cout << "\t\tLTran:   " << glm::to_string(camera.leftTranslate) << "\n\n";
            std::cout << "\t\tRTran:   " << glm::to_string(camera.rightTranslate) << "\n\n";


        }

        if (keysDown[kVK_Space]) {
            std::cout << "\tTranslation: " << glm::to_string(textureRotation) << "\n";
            std::cout << "\t Rotatation: " << glm::to_string(textureRotation) << "\n";
            std::cout << "\tTranslation: " << glm::to_string(textureRotation) << "\n\n";

            std::cout << "\tposVec:  " << glm::to_string(camera.posVec) << "\n";
            std::cout << "\tviewVec: " << glm::to_string(camera.viewVec) << "\n";
            std::cout << "\t\tlBView:  " << glm::to_string(camera.leftBackView) << "\n";
            std::cout << "\t\trBView:  " << glm::to_string(camera.rightBackView) << "\n";
            std::cout << "\t\trtView:  " << glm::to_string(camera.rightView) << "\n";
            std::cout << "\t\tltView:  " << glm::to_string(camera.leftView) << "\n\n";

            std::cout << "\tupVec:   " << glm::to_string(camera.upVec) << "\n";
            std::cout << "\trtVec:   " << glm::to_string(camera.rightVec) << "\n\n";

            std::cout << "\t\tproject: " << glm::to_string(camera.projection) << "\n";
            std::cout << "\t\tLproj:   " << glm::to_string(camera.leftProjection) << "\n";
            std::cout << "\t\tRproj:   " << glm::to_string(camera.rightProjection) << "\n\n";


            std::cout << "\t\tLTran:   " << glm::to_string(camera.leftTranslate) << "\n\n";
            std::cout << "\t\tRTran:   " << glm::to_string(camera.rightTranslate) << "\n\n";

        }
    }


    void initializeViews() {
        // This was a really helpful resource
        // http://stackoverflow.com/questions/349927/programmatically-creating-controls-in-cocoa
        // http://stackoverflow.com/questions/717442/how-do-i-create-cocoa-interfaces-without-interface-builder

        NSView *glv = makeGLView(400, 300);
        // ActionProxy* proxy = [[ActionProxy alloc] init:[NSValue valueWithPointer:this]];

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
        NSSplitView *parentView = [[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)];
        [parentView setVertical:YES];
        [window setContentView:parentView];

        [[window contentView] addSubview:glv];
        // [[window contentView] addSubview:view];
        [NSApp activateIgnoringOtherApps:YES]; //brings application to front on startup
        [NSApp run];
        printf("camera: %f, %f %f", camera.posVec.x, camera.posVec.y, camera.posVec.z);

    }
};

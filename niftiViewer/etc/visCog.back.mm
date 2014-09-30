//
// Created by Kyle Almryde on 4/5/14.
// Copyright (c) 2014 Angus Forbes. All rights reserved.
//

#include "Includes.hpp"
#include "Program.hpp"
#include "MeshBuffer.hpp"
#include "MeshUtils.hpp"
#include "MeshData.hpp"
using namespace aluminum;



class VisualCognition : public RendererOSX {

public:

    //set screen dimensions
    const int WIDTH  = 1280;
    const int HEIGHT = 960;

    // Shader programs
    Program graphShader, vfShader;

    //projection and modelview matrices
    glm::mat4  P = glm::mat4(1);
    glm::mat4 MV = glm::mat4(1);

    // Vertex struct for interleaved attributes
    struct point {
        GLfloat x;
        GLfloat y;
    };

    GLuint vao, vbo;
    GLuint vao1, vbo1;
    GLuint vao2, vbo2;

    glm::vec4 red = glm::vec4(1.0,0.0,0.0,1.0);
    glm::vec4 blue = glm::vec4(0.0,0.0,1.0,1.0);
    glm::vec4 green = glm::vec4(0.0,1.0,0.0,1.0);

    vector<glm::vec2> onsets;

    MeshBuffer quadLR;
    MeshBuffer quadUL;

    int idx = 0;
    bool idxFlag = true;
    float offset_x = 0.0f; //-13.3f;
    float scale_x = 1.0f; //0.625f;

    string RESOURCES = (string)[NSHomeDirectory() UTF8String] + "/Dropbox/XCodeProjects/aluminum/osx/examples/niftiViewer/Resources/";


/*---------------------------------------- Function Definitions ----------------------------------------*/

  /*
   *   Create Program object by loading existing file
   */
    void loadProgram(Program &p, const std::string &name) {

        p.create();
        p.attach(p.loadText(name + ".vsh"), GL_VERTEX_SHADER);
        glBindAttribLocation(p.id(), 0, "vert");
        p.attach(p.loadText(name + ".fsh"), GL_FRAGMENT_SHADER);

        p.link();
    }

    void initGraph(){

        glGenVertexArrays(1, &vao);
        glBindVertexArray(vao);

        glGenBuffers(1, &vbo);
        glBindBuffer(GL_ARRAY_BUFFER, vbo);

        loadModel(RESOURCES+"/pscalf/PAIGE_S23/043_016_001.1D", onsets);
//        loadModel(RESOURCES + "/models/visCog/LateLRVFsim.txt", onsets);
        printf("onset size is %lu\n",onsets.size());
        glBufferData(GL_ARRAY_BUFFER, 2*sizeof(float) * onsets.size(), &(onsets[0]), GL_STATIC_DRAW);
            glEnableVertexAttribArray((GLuint) graphShader.attribute("vert"));
            glVertexAttribPointer((GLuint) graphShader.attribute("vert"), 2, GL_FLOAT, GL_FALSE, 0, NULL);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);

    }

    void initShape(){
        GLfloat vertexData[] = {
                // X     Y    Z
                0.75f, 1.0f, 0.0f,
                0.5f, 0.5f, 0.0f,
                1.0f, 0.5f, 0.0f,
        };

        glGenVertexArrays(1, &vao1);
        glBindVertexArray(vao1);

        glGenBuffers(1, &vbo1);
        glBindBuffer(GL_ARRAY_BUFFER, vbo1);

        glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);
            glEnableVertexAttribArray((GLuint) graphShader.attribute("Position"));
            glVertexAttribPointer((GLuint) graphShader.attribute("Position"), 3, GL_FLOAT, GL_FALSE, 0, NULL);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);
    }

    void drawGraph() {

        graphShader.bind();
        {
            glUniform4fv(graphShader.uniform("g_color"), 1, glm::value_ptr(blue));
            glUniform1f(graphShader.uniform("offset_x"), offset_x);
            glUniform1f(graphShader.uniform("scale_x"), scale_x);
            glBindVertexArray(vao);
//            glDrawArrays(GL_LINE_STRIP, 0, onsets.size());
            glDrawArrays(GL_LINE_STRIP, 0, idx);
            glBindVertexArray(0);
        }
        graphShader.unbind();
    }

    void drawVisF() {

        switch(idx){
            case 2700:
                idxFlag = !idxFlag;
                break;
            case 0:
                idxFlag = !idxFlag;
                break;
            default:
                break;
        }

        vfShader.bind();
        {
            glUniform4fv(graphShader.uniform("g_color"), 1, glm::value_ptr(blue));
            glUniform1f(vfShader.uniform("g_scale"),onsets[idx].y+1);
            quadLR.draw();
            quadUL.draw();
//            glBindVertexArray(vao1);
//                glDrawArrays(GL_TRIANGLES, 0, 3);
//            glBindVertexArray(0);
        }
        vfShader.unbind();

    }

    void onCreate(){

        // load shader Program objects
        loadProgram(graphShader, RESOURCES+"shaders/graphShader");
        loadProgram(vfShader, RESOURCES+"shaders/vfShader");

        quadLR.init(MeshUtils::makeRectangle(glm::vec2(0.0,-0.5), glm::vec2(0.5,0.0), glm::vec2(0,0), glm::vec2(1,1)), 0, -1, -1, -1);
        quadUL.init(MeshUtils::makeRectangle(glm::vec2(-0.5,0.0), glm::vec2(0.0,0.5), glm::vec2(0,0), glm::vec2(1,1)), 0, -1, -1, -1);

        initGraph();
        initShape();

        printf("Initialization Complete!\n");
    }

    void handleKeys(){
        if (keysDown[kVK_ANSI_Q])
            exit(0);
        else if (keysDown[kVK_ANSI_A])
            offset_x -= 0.1;
        else if (keysDown[kVK_ANSI_D])
            offset_x += 0.1;
        else if (keysDown[kVK_ANSI_W])
            scale_x *= 0.5;
        else if (keysDown[kVK_ANSI_S])
            scale_x /= 0.5;

//        printf("offset: %f\tscale: %f\n",offset_x, scale_x);
    }

    void onFrame(){
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        handleKeys();

        if(idxFlag) ++idx;
        else --idx;

        drawVisF();
        drawGraph();

//        printf("onset.y: %f\t, onset.y+1: %f\n",onsets[idx].y, onsets[idx].y+1);
    }

    void onReshape(){}


    void initializeViews() {
        // This was a really helpful resource
        // http://stackoverflow.com/questions/349927/programmatically-creating-controls-in-cocoa
        // http://stackoverflow.com/questions/717442/how-do-i-create-cocoa-interfaces-without-interface-builder

        NSView *glv = makeGLView(WIDTH, HEIGHT);

        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        id appName = @"Visual Cognition Demo!";

        // Set up the window to hold the CocoaGL view
        id window = [CocoaGL setUpAppWindow:appName
                                          x:100
                                          y:100
                                          w:WIDTH
                                          h:HEIGHT];

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

private:

/************************* PRIVATE METHODS *************************/
/*******************************************************************/

/**
 * Method to join a string together, very helpful...
 * This thread helped with this function...
 * http://stackoverflow.com/questions/9277906/stdvector-to-string-with-custom-delimiter
 */
    std::string join(const vector<std::string> vec, const std::string delim="."){
        stringstream s;
        copy(vec.begin(),vec.end(),std::ostream_iterator<std::string>(s,delim.c_str()));
        std::string result = s.str();
        result.pop_back();
        return result;
    }


/**
 * Split a sting into a vector of elements
 * These two functions were taken from this thread via Stack Overflow, very helpful!
 * http://stackoverflow.com/questions/236129/how-to-split-a-string-in-c
 */
    std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
        std::stringstream ss(s);
        std::string item;
        while (std::getline(ss, item, delim)) {
            elems.push_back(item);
        }
        return elems;
    }

    std::vector<std::string> split(const std::string &s, char delim) {
        std::vector<std::string> elems;
        split(s, delim, elems);
        return elems;
    }

    std::vector<string> getFilename(std::string fname){
        vector<string> tokens = split(fname, '.');
        std::string type = tokens.back(); tokens.pop_back();
        std::string name = join(tokens);
        vector<string> result;
        result.push_back(name);
        result.push_back(type);
        return result;

    }

    /**
 * Builds a vector of onsets from 1D file
 * It is assumed values are newline delimited
 */
    void loadModel(string name, vector<glm::vec2> &onsets) {
        printf("%s\n",name.c_str());
        ifstream infile(name);
        float max = 0.0;
        if(infile){
            float value = 0.0;
            while(infile >> value){
                if (value > max) max = value;
                point pt;
                float x = 0.0;
                float y = value;
                onsets.push_back(glm::vec2(x,y));
            }
            float j = (onsets.size()/2.0)*-1;
            for (int i=0; i<onsets.size(); i++){
                onsets[i].x = (j/100.0);
                printf("x:%f\ty:%f\t",onsets[i].x,onsets[i].y);
                onsets[i].y = (onsets[i].y/max)-1.5;
                printf("y:%f\n",onsets[i].y);
                j++;
            }
        }
        infile.close();
    }

/**
 * Builds a vector of onsets from 1D file
 * It is assumed values are tab delimited
 */
    void loadTxT(string name, vector<glm::vec2>&onsets) {
        ifstream infile(name);
        string content((istreambuf_iterator<char>(infile)), (istreambuf_iterator<char>() ));
        vector<string> tokens = split(content, '\t');
        onsets.clear(); onsets.resize(tokens.size());
        for(int i = (-1 * tokens.size()/2); i < tokens.size();i++){
            float x = (i - 1000.0) / 100.0;
            float y = std::stof(tokens[i]);
            printf("x:%f\ty:%f\n",x,y);
            onsets.push_back(glm::vec2(x,y));
//            onsets[i].x = (float) i;
//            onsets[i].y = (float)::atof(tokens[i].c_str());
        }
        tokens.clear();
        infile.close();
    }


};


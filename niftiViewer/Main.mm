//
//  Main.cpp
//  niftiViewer
//
//  Created by Angus Forbes on 7/7/13.
//  Copyright (c) 2013 Angus Forbes. All rights reserved.
//

//#include "Raycast.mm"
//#include "RaycastFBO.mm"
//#include "DepthPeel.mm"
// #include "DualDepthPeel.mm"
#include "NiftiViewer.mm"

int main() {
#ifdef HAVE_ZLIB
    fprintf(stderr,"in MAIN.mm HAVE_ZLIB = 1\n");
#else
    fprintf(stderr,"in MAIN.mm HAVE_ZLIB = 0\n");
#endif

    NiftiViewer().start();

//
//    // This was a really helpful resource
//    // http://stackoverflow.com/questions/349927/programmatically-creating-controls-in-cocoa
//    // http://stackoverflow.com/questions/717442/how-do-i-create-cocoa-interfaces-without-interface-builder
//
//    /***********************
//    *       SETUP
//    ***********************/
//
//   NSView *glv = nifti.makeGLView(1600, 850);
//
//   ActionProxy *proxy = [[[ActionProxy alloc] init:[NSValue valueWithPointer:&nifti]] autorelease];
//
//   [NSApplication sharedApplication];
//   [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
//   id appName = @"3D+Time Brain View";
//
//   // Set up the window to hold the CocoaGL view
//   id window = [CocoaGL setUpAppWindow:appName x:200 y:150 w:1200 h:850];
//
//   [CocoaGL setUpMenuBar:(CocoaGL *) glv name:appName];
//
//   // need to look into how to autoresize the window, until then its not useful to use a regular view,
//   // we are stuck with NSSplitView
//   // setContentView:viewParent];
//   NSSplitView *viewParent = [[[NSSplitView alloc] initWithFrame:NSMakeRect(0, 0, 400, 300)] autorelease];
//   [viewParent setVertical:YES];
//   [window setContentView:viewParent];
//
//
//   /***********************
//   *       VIEWS
//   ***********************/
//   /*** Local Time Drawer-View ***/
//   NSView *viewDrawerLocalTimePane = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 360)] autorelease];  // This is a view for the drawer
//   nifti.drawerTimePane = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200.0, 150.0) preferredEdge:NSMinYEdge];  // Now if only I could get the drawer on the left side...
//   [nifti.drawerTimePane setContentView:viewDrawerLocalTimePane];
//   [nifti.drawerTimePane setParentWindow:window];
//   [nifti.drawerTimePane open];
//
//
//   /*** NiftiImage Controler Drawer-View ***/
//   NSView *viewDrawerCluster = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 360)] autorelease];  // This is a view for the drawer
//   nifti.drawerCluster = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200.0, 150.0) preferredEdge:NSMinXEdge];  // Now if only I could get the drawer on the left side...
//   [nifti.drawerCluster setContentView:viewDrawerCluster];
//   [nifti.drawerCluster setParentWindow:window];
//   [nifti.drawerCluster open];
//
//   /*** Brain Cutout Drawer-View ***/
//   NSView *viewDrawerSlicePane = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, 150, 360)] autorelease];  // This is a view for the drawer
//   nifti.drawerSlicePane = [[NSDrawer alloc] initWithContentSize:NSMakeSize(200.0, 150.0) preferredEdge:NSMinYEdge];  // Now if only I could get the drawer on the left side...
//   [nifti.drawerSlicePane setContentView:viewDrawerSlicePane];
//   [nifti.drawerSlicePane setParentWindow:window];
//   [nifti.drawerSlicePane close];
//
//
//
//   /***********************
//   *       SLIDERS
//   ***********************/
//
//   // Local-Time slider
//   nifti.localTimeSlider = [[[NSSlider alloc] initWithFrame:NSMakeRect(10, 50, 800, 40)] autorelease];
//   [nifti.localTimeSlider setMinValue:0.0];
//   [nifti.localTimeSlider setMaxValue:1.0];
//   [nifti.localTimeSlider setTarget:proxy];
//   [nifti.localTimeSlider setTitle:@"Time Position"];
//   [nifti.localTimeSlider setNumberOfTickMarks:nifti.numSamples];
//   [nifti.localTimeSlider setAllowsTickMarkValuesOnly:NO];
//   [nifti.localTimeSlider setAction:@selector(adjustTime:)];
//   [nifti.localTimeSlider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.localIndex = [nifti.localTimeSlider floatValue];
//
//   // Brain Opacity slider
//   nifti.opacitySlider = [[[NSSlider alloc] initWithFrame:NSMakeRect(10, 30, 190, 40)] autorelease];
//   [nifti.opacitySlider setMinValue:0.0];
//   [nifti.opacitySlider setMaxValue:1.0];
//   [nifti.opacitySlider setTarget:proxy];
//   [nifti.opacitySlider setTitle:@"Brain Opacity"];
//   [nifti.opacitySlider setNumberOfTickMarks:10];
//   [nifti.opacitySlider setAllowsTickMarkValuesOnly:NO];
//   [nifti.opacitySlider setAction:@selector(adjustOpacity:)];
//   [nifti.opacitySlider setFloatValue:100.0];  // Sets the position of the Slider!
//   nifti.brainOpacity = [nifti.opacitySlider floatValue];
//
//   // Global-Time slider
//   nifti.globalTimeSlider = [[[NSSlider alloc] initWithFrame:NSMakeRect(10, 0, 190, 40)] autorelease];
//   [nifti.globalTimeSlider setMinValue:0.0];
//   [nifti.globalTimeSlider setMaxValue:1.0];
//   [nifti.globalTimeSlider setTarget:proxy];
//   [nifti.globalTimeSlider setTitle:@"Time Position"];
//   [nifti.globalTimeSlider setNumberOfTickMarks:3];
//   [nifti.globalTimeSlider setAllowsTickMarkValuesOnly:NO];
//   [nifti.globalTimeSlider setAction:@selector(adjustTime:)];
//   [nifti.globalTimeSlider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.globalIndex = [nifti.globalTimeSlider floatValue];
//
//   // Angle slider
//   nifti.angleSlider = [[[NSSlider alloc] initWithFrame:NSMakeRect(600, 80, 190, 40)] autorelease];
//   [nifti.angleSlider setMinValue:0.0];
//   [nifti.angleSlider setMaxValue:360.0];
//   [nifti.angleSlider setTarget:proxy];
//   [nifti.angleSlider setTitle:@"Left X:"];
//   [nifti.angleSlider setAllowsTickMarkValuesOnly:NO];
//   [nifti.angleSlider setAction:@selector(rotateL:)];
//   [nifti.angleSlider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.angle = [nifti.angleSlider floatValue];
//
//
//   // Cutout sliders //
//
//   // Start* slider
//   nifti.startXslider = [[[NSSlider alloc] initWithFrame:NSMakeRect(10, 100, 190, 40)] autorelease];
//   [nifti.startXslider setMinValue:0.0];
//   [nifti.startXslider setMaxValue:1.0];
//   [nifti.startXslider setTarget:proxy];
//   [nifti.startXslider setTitle:@"Left X:"];
//   [nifti.startXslider setAllowsTickMarkValuesOnly:NO];
//   [nifti.startXslider setAction:@selector(beginCutOut:)];
//   [nifti.startXslider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.beginXYZ.x = [nifti.startXslider floatValue];
//
//   nifti.startYslider = [[[NSSlider alloc] initWithFrame:NSMakeRect(10, 50, 190, 40)] autorelease];
//   [nifti.startYslider setMinValue:0.0];
//   [nifti.startYslider setMaxValue:1.0];
//   [nifti.startYslider setTarget:proxy];
//   [nifti.startYslider setTitle:@"Left Y:"];
//   [nifti.startYslider setAllowsTickMarkValuesOnly:NO];
//   [nifti.startYslider setAction:@selector(beginCutOut:)];
//   [nifti.startYslider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.beginXYZ.y = [nifti.startYslider floatValue];
//
//   nifti.startZslider = [[[NSSlider alloc] initWithFrame:NSMakeRect(10, 0, 190, 40)] autorelease];
//   [nifti.startZslider setMinValue:0.0];
//   [nifti.startZslider setMaxValue:1.0];
//   [nifti.startZslider setTarget:proxy];
//   [nifti.startZslider setTitle:@"Left Z:"];
//   [nifti.startZslider setAllowsTickMarkValuesOnly:NO];
//   [nifti.startZslider setAction:@selector(beginCutOut:)];
//   [nifti.startZslider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.beginXYZ.z = [nifti.startZslider floatValue];
//
//   // End* slider
//   nifti.endXslider = [[[NSSlider alloc] initWithFrame:NSMakeRect(200, 100, 190, 40)] autorelease];
//   [nifti.endXslider setMinValue:0.0];
//   [nifti.endXslider setMaxValue:1.0];
//   [nifti.endXslider setTarget:proxy];
//   [nifti.endXslider setTitle:@"Right X:"];
//   [nifti.endXslider setAllowsTickMarkValuesOnly:NO];
//   [nifti.endXslider setAction:@selector(endCutOut:)];
//   [nifti.endXslider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.endXYZ.x = [nifti.endXslider floatValue];
//
//   nifti.endYslider = [[[NSSlider alloc] initWithFrame:NSMakeRect(200, 50, 190, 40)] autorelease];
//   [nifti.endYslider setMinValue:0.0];
//   [nifti.endYslider setMaxValue:1.0];
//   [nifti.endYslider setTarget:proxy];
//   [nifti.endYslider setTitle:@"Right Y:"];
//   [nifti.endYslider setAllowsTickMarkValuesOnly:NO];
//   [nifti.endYslider setAction:@selector(endCutOut:)];
//   [nifti.endYslider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.endXYZ.y = [nifti.endYslider floatValue];
//
//   nifti.endZslider = [[[NSSlider alloc] initWithFrame:NSMakeRect(200, 0, 190, 40)] autorelease];
//   [nifti.endZslider setMinValue:0.0];
//   [nifti.endZslider setMaxValue:1.0];
//   [nifti.endZslider setTarget:proxy];
//   [nifti.endZslider setTitle:@"Right Z:"];
//   [nifti.endZslider setAllowsTickMarkValuesOnly:NO];
//   [nifti.endZslider setAction:@selector(endCutOut:)];
//   [nifti.endZslider setFloatValue:0.0];  // Sets the position of the Slider!
//   nifti.endXYZ.z = [nifti.endZslider floatValue];
//
//
//   /*************************
//   *         BUTTONS
//   * ************************/
//   // Toggle Brain Cutout
//   nifti.buttonToggleSlices = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 500, 150, 40)] autorelease];
//   [nifti.buttonToggleSlices setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonToggleSlices setButtonType:NSSwitchButton];
//   [nifti.buttonToggleSlices setTitle:@"Cutout Slices"];
//   [nifti.buttonToggleSlices setTarget:proxy];
//   [nifti.buttonToggleSlices setState:NSOffState];
//   [nifti.buttonToggleSlices setAction:@selector(toggleSlicesCutout:)];
//   nifti.toggleSlices = 0;
//
//   // Toggle NiftiImage Cutout
//   nifti.buttonToggleCluster = [[[NSButton alloc] initWithFrame:NSMakeRect(600, 100, 150, 40)] autorelease];
//   [nifti.buttonToggleCluster setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonToggleCluster setButtonType:NSSwitchButton];
//   [nifti.buttonToggleCluster setTitle:@"Cutout clusters?"];
//   [nifti.buttonToggleCluster setTarget:proxy];
//   [nifti.buttonToggleCluster setState:NSOffState];
//   [nifti.buttonToggleCluster setAction:@selector(toggleClustersCutout:)];
//   nifti.toggleCluster = 0;
//
//
//   // Toggle Local Time
//   nifti.buttonUseLocalTime = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 470, 150, 40)] autorelease];
//   [nifti.buttonUseLocalTime setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonUseLocalTime setButtonType:NSSwitchButton];
//   [nifti.buttonUseLocalTime setTitle:@"Use Local Time"];
//   [nifti.buttonUseLocalTime setTarget:proxy];
//   [nifti.buttonUseLocalTime setState:NSOffState];
//   [nifti.buttonUseLocalTime setAction:@selector(toggleUseLocalTime:)];
//   nifti.useLocalTime = 0;
//
//   // Toggle Global Time
//   nifti.buttonUseGlobalTime = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 430, 150, 40)] autorelease];
//   [nifti.buttonUseGlobalTime setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonUseGlobalTime setButtonType:NSSwitchButton];
//   [nifti.buttonUseGlobalTime setTitle:@"Use Global Time"];
//   [nifti.buttonUseGlobalTime setTarget:proxy];
//   [nifti.buttonUseGlobalTime setState:NSOnState];
//   [nifti.buttonUseGlobalTime setAction:@selector(toggleUseGlobalTime:)];
//   nifti.useGlobalTime = 1;
//
//   /*** CLUSTER CONTROLS ***/
//   nifti.buttonOpenVolume0 = [[[NSButton alloc] initWithFrame:NSMakeRect(40, 240, 150, 40)] autorelease];
//   [nifti.buttonOpenVolume0 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonOpenVolume0 setButtonType:NSMomentaryLightButton];
//   [nifti.buttonOpenVolume0 setTitle:@"Set Brain"];
//   [nifti.buttonOpenVolume0 setTarget:proxy];
//   [nifti.buttonOpenVolume0 setAction:@selector(openVolume0:)];
//
//   nifti.buttonToggleVolume0 = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 240, 90, 40)] autorelease];  // Instantiate it, and describe its size and location
//   [nifti.buttonToggleVolume0 setBezelStyle:NSRoundedBezelStyle];     // sets the bezelStyle
//   [nifti.buttonToggleVolume0 setButtonType:NSSwitchButton];      // sets the button Type, I wanted a SwitchButton
//   [nifti.buttonToggleVolume0 setTitle:@""];  // Good to know, I can call @"SomeString" and it will cast it as NSString
//   [nifti.buttonToggleVolume0 setTarget:proxy];        // link it to ActionProxy
//   [nifti.buttonToggleVolume0 setState:NSOnState];     // I want the button to be 'On' when it is displaying a color
//   [nifti.buttonToggleVolume0 setAction:@selector(toggleVolume0:)];      // link the method
//
//   // Setting up the button to toggle time 1
//   nifti.buttonOpenVolume1 = [[[NSButton alloc] initWithFrame:NSMakeRect(40, 210, 150, 40)] autorelease];
//   [nifti.buttonOpenVolume1 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonOpenVolume1 setButtonType:NSMomentaryLightButton];
//   [nifti.buttonOpenVolume1 setTitle:@"Set Image"];
//   [nifti.buttonOpenVolume1 setTarget:proxy];
//   [nifti.buttonOpenVolume1 setAction:@selector(openVolume1:)];
//
//   nifti.buttonToggleVolume1 = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 210, 90, 40)] autorelease];  // Instantiate it, and describe its size and location
//   [nifti.buttonToggleVolume1 setBezelStyle:NSRoundedBezelStyle];     // sets the bezelStyle
//   [nifti.buttonToggleVolume1 setButtonType:NSSwitchButton];      // sets the button Type, I wanted a SwitchButton
//   [nifti.buttonToggleVolume1 setTitle:@""];  // Good to know, I can call @"SomeString" and it will cast it as NSString
//   [nifti.buttonToggleVolume1 setTarget:proxy];        // link it to ActionProxy
//   [nifti.buttonToggleVolume1 setState:NSOnState];     // I want the button to be 'On' when it is displaying a color
//   [nifti.buttonToggleVolume1 setAction:@selector(toggleVolume1:)];      // link the method
//
//
//
//   // Setting up the button to toggle time 2
//   nifti.buttonOpenVolume2 = [[[NSButton alloc] initWithFrame:NSMakeRect(40, 180, 150, 40)] autorelease];
//   [nifti.buttonOpenVolume2 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonOpenVolume2 setButtonType:NSMomentaryLightButton];
//   [nifti.buttonOpenVolume2 setTitle:@"Set Image"];
//   [nifti.buttonOpenVolume2 setTarget:proxy];
//   [nifti.buttonOpenVolume2 setAction:@selector(openVolume2:)];
//
//   nifti.buttonToggleVolume2 = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 180, 90, 40)] autorelease];
//   [nifti.buttonToggleVolume2 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonToggleVolume2 setButtonType:NSSwitchButton];
//   [nifti.buttonToggleVolume2 setTitle:@""];
//   [nifti.buttonToggleVolume2 setTarget:proxy];
//   [nifti.buttonToggleVolume2 setState:NSOnState];
//   [nifti.buttonToggleVolume2 setAction:@selector(toggleVolume2:)];
//
//
//   // Setting up the button to toggle time 2
//   nifti.buttonOpenVolume3 = [[[NSButton alloc] initWithFrame:NSMakeRect(40, 150, 150, 40)] autorelease];
//   [nifti.buttonOpenVolume3 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonOpenVolume3 setButtonType:NSMomentaryLightButton];
//   [nifti.buttonOpenVolume3 setTitle:@"Set Image"];
//   [nifti.buttonOpenVolume3 setTarget:proxy];
//   [nifti.buttonOpenVolume3 setAction:@selector(openVolume3:)];
//
//   nifti.buttonToggleVolume3 = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 150, 90, 40)] autorelease];
//   [nifti.buttonToggleVolume3 setBezelStyle: NSRoundedBezelStyle];
//   [nifti.buttonToggleVolume3 setButtonType:NSSwitchButton];
//   [nifti.buttonToggleVolume3 setTitle:@""];
//   [nifti.buttonToggleVolume3 setTarget:proxy];
//   [nifti.buttonToggleVolume3 setState:NSOnState];
//   [nifti.buttonToggleVolume3 setAction:@selector(toggleVolume3:)];
//
//
//
//   // Setting up the button to toggle time 4
//   nifti.buttonOpenVolume4 = [[[NSButton alloc] initWithFrame:NSMakeRect(40, 120, 150, 40)] autorelease];
//   [nifti.buttonOpenVolume4 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonOpenVolume4 setButtonType:NSMomentaryLightButton];
//   [nifti.buttonOpenVolume4 setTitle:@"Set Image"];
//   [nifti.buttonOpenVolume4 setTarget:proxy];
//   [nifti.buttonOpenVolume4 setAction:@selector(openVolume4:)];
//
//   nifti.buttonToggleVolume4 = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 120, 90, 40)] autorelease];
//   nifti.buttonToggleVolume4.bezelStyle = NSRoundedBezelStyle;
//   [nifti.buttonToggleVolume4 setButtonType:NSSwitchButton];
//   [nifti.buttonToggleVolume4 setTitle:@""];
//   [nifti.buttonToggleVolume4 setTarget:proxy];
//   [nifti.buttonToggleVolume4 setState:NSOnState];
//   [nifti.buttonToggleVolume4 setAction:@selector(toggleVolume4:)];
//
//   // Setting up the button to toggle time 5
//   nifti.buttonOpenVolume5 = [[[NSButton alloc] initWithFrame:NSMakeRect(40, 90, 150, 40)] autorelease];
//   [nifti.buttonOpenVolume5 setBezelStyle:NSRoundedBezelStyle];
//   [nifti.buttonOpenVolume5 setButtonType:NSMomentaryLightButton];
//   [nifti.buttonOpenVolume5 setTitle:@"Set Image"];
//   [nifti.buttonOpenVolume5 setTarget:proxy];
//   [nifti.buttonOpenVolume5 setAction:@selector(openVolume5:)];
//
//   nifti.buttonToggleVolume5 = [[[NSButton alloc] initWithFrame:NSMakeRect(10, 90, 90, 40)] autorelease];
//   nifti.buttonToggleVolume5.bezelStyle = NSRoundedBezelStyle;
//   [nifti.buttonToggleVolume5 setButtonType:NSSwitchButton];
//   [nifti.buttonToggleVolume5 setTitle:@""];
//   [nifti.buttonToggleVolume5 setTarget:proxy];
//   [nifti.buttonToggleVolume5 setState:NSOnState];
//   [nifti.buttonToggleVolume5 setAction:@selector(toggleVolume5:)];
//
//
//   /*************************
//   *       ATTACH VIEWS     *
//   **************************/
//   [viewDrawerCluster addSubview:nifti.buttonToggleVolume0];  //  add it to the drawer view
//   [viewDrawerCluster addSubview:nifti.buttonToggleVolume1];
//   [viewDrawerCluster addSubview:nifti.buttonToggleVolume2];
//   [viewDrawerCluster addSubview:nifti.buttonToggleVolume3];
//   [viewDrawerCluster addSubview:nifti.buttonToggleVolume4];
//   [viewDrawerCluster addSubview:nifti.buttonToggleVolume5];
//   [viewDrawerCluster addSubview:nifti.buttonOpenVolume0];
//   [viewDrawerCluster addSubview:nifti.buttonOpenVolume1];
//   [viewDrawerCluster addSubview:nifti.buttonOpenVolume2];
//   [viewDrawerCluster addSubview:nifti.buttonOpenVolume3];
//   [viewDrawerCluster addSubview:nifti.buttonOpenVolume4];
//   [viewDrawerCluster addSubview:nifti.buttonOpenVolume5];
//
//   [viewDrawerCluster addSubview:nifti.buttonUseLocalTime];
//   [viewDrawerCluster addSubview:nifti.buttonUseGlobalTime];
//   [viewDrawerCluster addSubview:nifti.buttonToggleSlices];
//   [viewDrawerCluster addSubview:nifti.opacitySlider];
//   [viewDrawerCluster addSubview:nifti.globalTimeSlider];
//
//   [viewDrawerSlicePane addSubview:nifti.buttonToggleCluster];
//   [viewDrawerSlicePane addSubview:nifti.angleSlider];
//   [viewDrawerSlicePane addSubview:nifti.startXslider];
//   [viewDrawerSlicePane addSubview:nifti.startYslider];
//   [viewDrawerSlicePane addSubview:nifti.startZslider];
//   [viewDrawerSlicePane addSubview:nifti.endXslider];
//   [viewDrawerSlicePane addSubview:nifti.endYslider];
//   [viewDrawerSlicePane addSubview:nifti.endZslider];
//
//   [viewDrawerLocalTimePane addSubview:nifti.localTimeSlider];
//
//   [[window contentView] addSubview:glv];
//
//   [NSApp activateIgnoringOtherApps:YES]; //brings application to front on startup
//   [NSApp run];

    return 0;
};

/**

 The answers to :
 http://stackoverflow.com/questions/8948401/handle-cocoa-setaction-message-in-objective-c
 http://stackoverflow.com/questions/1928152/passing-a-c-object-with-an-objective-c-cocoa-event-performselector

 Were VERY helpful in figuring out how to send messages from obj-c widgets to C++
 **/

#import "ActionProxy.h"
//#import "Slices.mm"
//#import "Raycast.mm"
#import "RaycastFBO.mm"
//#import "NiftiView.mm"

@interface ActionProxy ()
  - (void)toggleVolume:(id)sender :(bool *)clusterOn :(vec4 *)color;
  - (void)openVolume:(id)sender :(NiftiImage *)image:(NSButton*)button;
  - (void)toggleDrawer:(id)sender :(NSDrawer *)drawerOn:(NSDrawer *)drawerOff;

@end

@implementation ActionProxy
    - (id)init:(NSValue *)_target {
        [super init];
        target = _target;
        return self;
    }

//- (void)adjustOpacity:(id)sender {((Raycast *) [target pointerValue])->adjustOpacity();}
//
//- (void)openVolume:(id)sender {((Raycast *) [target pointerValue])->openVolume();}
//
//- (void)toggleVolume0:(id)sender {((Raycast *) [target pointerValue])->toggleVolume0();}
//- (void)toggleVolume1:(id)sender {((Raycast *) [target pointerValue])->toggleVolume1();}
//- (void)toggleVolume2:(id)sender {((Raycast *) [target pointerValue])->toggleVolume2();}
//- (void)toggleVolume3:(id)sender {((Raycast *) [target pointerValue])->toggleVolume3();}
//- (void)toggleVolume4:(id)sender {((Raycast *) [target pointerValue])->toggleVolume4();}
//- (void)toggleVolume5:(id)sender {((Raycast *) [target pointerValue])->toggleVolume5();}
//
//- (void)adjustTime:(id)sender {((Raycast *) [target pointerValue])->adjustTime();}
//- (void)toggleUseLocalTime:(id)sender{((Raycast *) [target pointerValue])->toggleUseLocalTime();}
//- (void)toggleUseGlobalTime:(id)sender{((Raycast *) [target pointerValue])->toggleUseGlobalTime();}
//
//
//- (void)toggleSlicesCutout:(id)sender {((Raycast *) [target pointerValue])->toggleSlicesCutout();}
//- (void)toggleClustersCutout:(id)sender {((Raycast *) [target pointerValue])->toggleClustersCutout();}
//
//
//- (void)cutoutLx:(id)sender {((Raycast *) [target pointerValue])->cutoutLx();}
//- (void)cutoutLy:(id)sender {((Raycast *) [target pointerValue])->cutoutLy();}
//- (void)cutoutLz:(id)sender {((Raycast *) [target pointerValue])->cutoutLz();}
//- (void)cutoutRx:(id)sender {((Raycast *) [target pointerValue])->cutoutRx();}
//- (void)cutoutRy:(id)sender {((Raycast *) [target pointerValue])->cutoutRy();}
//- (void)cutoutRz:(id)sender {((Raycast *) [target pointerValue])->cutoutRz();}


//- (void)toggleDrawer:(id)sender:(NSDrawer *)drawerOn:(NSDrawer *)drawerOff {
//    ((Raycast *) [target pointerValue])->toggleDrawer(drawerOn, drawerOff);
//}

//==========================================================================================


    - (void)adjustOpacity:(id)sender {((RaycastFBO *) [target pointerValue])->adjustOpacity();}

//    - (void)openVolume:(id)sender:(NiftiImage *)image {((RaycastFBO *) [target pointerValue])->openVolume(image);}

    - (void)openVolume0:(id)sender {((RaycastFBO *) [target pointerValue])->openVolume0();}
    - (void)openVolume1:(id)sender {((RaycastFBO *) [target pointerValue])->openVolume1();}
    - (void)openVolume2:(id)sender {((RaycastFBO *) [target pointerValue])->openVolume2();}
    - (void)openVolume3:(id)sender {((RaycastFBO *) [target pointerValue])->openVolume3();}
    - (void)openVolume4:(id)sender {((RaycastFBO *) [target pointerValue])->openVolume4();}
    - (void)openVolume5:(id)sender {((RaycastFBO *) [target pointerValue])->openVolume5();}

//    - (void)toggleVolume:(id)sender:(bool *)clusterOn:(vec4 *)color {
//        ((RaycastFBO *) [target pointerValue])->toggleVolume(clusterOn, color);
//    }
    - (void)toggleVolume0:(id)sender {((RaycastFBO *) [target pointerValue])->toggleVolume0();}
    - (void)toggleVolume1:(id)sender {((RaycastFBO *) [target pointerValue])->toggleVolume1();}
    - (void)toggleVolume2:(id)sender {((RaycastFBO *) [target pointerValue])->toggleVolume2();}
    - (void)toggleVolume3:(id)sender {((RaycastFBO *) [target pointerValue])->toggleVolume3();}
    - (void)toggleVolume4:(id)sender {((RaycastFBO *) [target pointerValue])->toggleVolume4();}
    - (void)toggleVolume5:(id)sender {((RaycastFBO *) [target pointerValue])->toggleVolume5();}

    - (void)adjustTime:(id)sender {((RaycastFBO *) [target pointerValue])->adjustTime();}
    - (void)toggleUseLocalTime:(id)sender{((RaycastFBO *) [target pointerValue])->toggleUseLocalTime();}
    - (void)toggleUseGlobalTime:(id)sender{((RaycastFBO *) [target pointerValue])->toggleUseGlobalTime();}


    - (void)toggleSlicesCutout:(id)sender {((RaycastFBO *) [target pointerValue])->toggleSlicesCutout();}
    - (void)toggleClustersCutout:(id)sender {((RaycastFBO *) [target pointerValue])->toggleClustersCutout();}

    - (void)rotateL:(id)sender {((RaycastFBO *) [target pointerValue])->rotateL();}
    - (void)beginCutOut:(id)sender {((RaycastFBO *) [target pointerValue])->beginCutOut();}
    - (void)endCutOut:(id)sender {((RaycastFBO *) [target pointerValue])->endCutOut();}

//    - (void)cutoutLx:(id)sender {((RaycastFBO *) [target pointerValue])->cutoutLx();}
//    - (void)cutoutLy:(id)sender {((RaycastFBO *) [target pointerValue])->cutoutLy();}
//    - (void)cutoutLz:(id)sender {((RaycastFBO *) [target pointerValue])->cutoutLz();}
//    - (void)cutoutRx:(id)sender {((RaycastFBO *) [target pointerValue])->cutoutRx();}
//    - (void)cutoutRy:(id)sender {((RaycastFBO *) [target pointerValue])->cutoutRy();}
//    - (void)cutoutRz:(id)sender {((RaycastFBO *) [target pointerValue])->cutoutRz();}


@end

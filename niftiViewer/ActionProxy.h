#ifndef INCLUDE_PROXY
#define INCLUDE_PROXY

#import <Aluminum/Aluminum.h>
//#import "Includes.hpp"
//#import "RendererOSX.h"
//#import "NiftiImage.h"
//#import <Foundation/Foundation.h>

@interface ActionProxy : NSObject {
      NSValue *target;
  }

  - (id)init:(NSValue *)_target;
  - (void)openVolume0:(id)sender;
  - (void)openVolume1:(id)sender;
  - (void)openVolume2:(id)sender;
  - (void)openVolume3:(id)sender;
  - (void)openVolume4:(id)sender;
  - (void)openVolume5:(id)sender;

  - (void)toggleVolume0:(id)sender;
  - (void)toggleVolume1:(id)sender;
  - (void)toggleVolume2:(id)sender;
  - (void)toggleVolume3:(id)sender;
  - (void)toggleVolume4:(id)sender;
  - (void)toggleVolume5:(id)sender;

  - (void)adjustOpacity:(id)sender;

  - (void)adjustTime:(id)sender;
  - (void)toggleUseLocalTime:(id)sender;
  - (void)toggleUseGlobalTime:(id)sender;


  - (void)toggleSlicesCutout:(id)sender;
  - (void)toggleClustersCutout:(id)sender;

  - (void)rotateL:(id)sender;
  - (void)cutoutLx:(id)sender;
  - (void)cutoutLy:(id)sender;
  - (void)cutoutLz:(id)sender;
  - (void)cutoutRx:(id)sender;
  - (void)cutoutRy:(id)sender;
  - (void)cutoutRz:(id)sender;
//-(void) toggleCluster: (id)sender cluster_On:(bool*)cluster_On cluster_color:(glm::vec4*)cluster_color;

@end

#endif
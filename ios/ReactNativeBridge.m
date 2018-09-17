//
//  ReactNativeBridge.m
//  sampleAcko
//
//  Created by Pushpendra Khandelwal on 14/09/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTConvert.h>

//RCTResponseSenderBlock

@interface RCT_EXTERN_MODULE(NativeClickHandler, NSObject)

RCT_EXTERN_METHOD(didButtonClick);
RCT_EXTERN_METHOD(permissionNotGranted);

@end

@interface RCT_EXTERN_MODULE(ZendriveHelper, NSObject)

RCT_EXTERN_METHOD(setUpAndStartZenDrive:(NSString*)userId)
RCT_EXTERN_METHOD(disableZenDrive)

@end

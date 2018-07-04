//
//  DStarUtils.m
//  DStarEngine
//
//  Created by Dave Carlton on 6/30/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import "DStarUtils.h"
#import "DStarEngine.h"
#import <Foundation/Foundation.h>

const NSString *DSTARAUTHHOST = @"opendstar.org";
const NSString *DEFAULT_VOCODER = @"DSDV3KSerialVocoder";
@implementation DSVars

+ (DSVars *) shared {
    static DSVars *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance setAudioHandler: nil];
    });
    return sharedInstance;
}

@end


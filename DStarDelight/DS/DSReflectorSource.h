//
// Created by Dave Carlton on 7/13/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DSReflector.h"

// References a reflector source on the internet
@interface DSReflectorSource : DSReflector

@property NSURL *url;
@property NSError *lastResponse;
@property NSDate *lastUpdate;

- (void)initWithName: (NSString *)name;
- (BOOL)isActive;

@end

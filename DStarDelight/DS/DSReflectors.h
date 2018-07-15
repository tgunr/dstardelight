//
//  DSReflectors.h
//  DStarDelight
//
//  Created by Dave Carlton on 7/13/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern const NSString *masterGatewaysListURL;
extern const NSString *SOURCE_HEADER;

@interface DSReflectors : NSObject

// Array of DSReflectorSource
@property NSMutableArray *reflectorSources;
// Dictionary of reflector
@property NSMutableArray *reflectors;

- (DSReflectors *)init;

void checkIfOutdated();
- (void)updateReflectors;

- (void)checkForOutDated;
@end

NS_ASSUME_NONNULL_END

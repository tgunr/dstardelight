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
@property NSMutableArray *reflectorGateways;

- (DSReflectors *)savedReflectors;

- (NSURL *)reflectorsURL;

- (void)asyncLoadReflectors:(NSURL *)url usingBlock:(void (^)(void))block;

- (void)loadReflectors:(NSURL *)url;

- (void)reloadReflectors;

- (void)checkForOutDated;

- (void)updateReflectors;

@end

NS_ASSUME_NONNULL_END

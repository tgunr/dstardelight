
#import <Foundation/Foundation.h>

#import "DSEVocoderDriver.h"

@class DSEAudioHandler;

@interface DSEDV3KVocoder : NSObject <DSEVocoderDriver>

- (id) init;

@property (nonatomic, readonly, copy) NSString *productId;
@property (nonatomic, readonly, copy) NSString *version;

@end

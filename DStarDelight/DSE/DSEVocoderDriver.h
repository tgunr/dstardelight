
#import <Foundation/Foundation.h>

@protocol DSELinkDriverProtocol;

@class DSAudioHandler;
@class NSViewController;

@protocol DSEVocoderDriver <NSObject>
- (void) decodeData:(void *) data lastPacket:(BOOL)last;
- (void) encodeData:(void *) data lastPacket:(BOOL)last;

- (BOOL) start;
- (void) stop;

+(NSString *)driverName;

@property (nonatomic) DSAudioHandler *audio;
@property (nonatomic) NSObject <DSELinkDriverProtocol> *network;
@property (nonatomic) NSViewController *configurationViewController;

@end

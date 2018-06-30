
#import <Foundation/Foundation.h>

@protocol DSELinkDriverProtocol;

@class STUBAudioHandler;

@protocol DSEVocoderDriver <NSObject>
- (void) decodeData:(void *) data lastPacket:(BOOL)last;
- (void) encodeData:(void *) data lastPacket:(BOOL)last;

- (BOOL) start;
- (void) stop;

+(NSString *)driverName;

@property (nonatomic) STUBAudioHandler *audio;
@property (nonatomic) NSObject <DSELinkDriverProtocol> *network;
//@property (nonatomic, readonly) NSViewController *configurationViewController;

@end

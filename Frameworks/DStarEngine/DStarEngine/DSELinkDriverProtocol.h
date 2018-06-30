

#import "DSEVocoderDriver.h"
#import "DSELinkDriverDelegate.h"

enum linkState {
    UNLINKED,
    CONNECTED,
    LINKING,
    LINKED
};

@protocol DSELinkDriverProtocol

-(BOOL)canHandleLinkTo:(NSString *)reflector;

@property (nonatomic, readonly, copy) NSString *linkTarget;
@property (nonatomic) id <DSEVocoderDriver> vocoder;
@property (nonatomic, copy)NSString *myCall;
@property (nonatomic, copy)NSString *myCall2;
@property (nonatomic, weak) NSObject <DSELinkDriverDelegate> *delegate;
@property (nonatomic) dispatch_queue_t linkQueue;
@property (nonatomic, readonly) NSArray<NSString *> *destinations;

-(void)linkTo:(NSString *)linkTarget;
-(void)unlink;

-(void) sendAMBE:(void *)data lastPacket:(BOOL)last;
@end 

//
//  DSEDataEngine.h
//

#import "DStarEngine.h"
#import "DSELinkDriverDelegate.h"
#import "DSESlowDataCoder.h"
#import "DSEDataEngineDelegate.h"
//#import "/Sources/HAM/DStarDelight/DerivedData/Build/Intermediates.noindex/DStarDelight.build/Debug/DStarDelight.build/DerivedSources/DStarDelight-Swift.h"

@class AppDelegate;

@interface DSEDataEngine : NSObject <DSELinkDriverDelegate, DSESlowDataDelegate>

@property (nonatomic, readonly) NSObject <DSELinkDriverProtocol> *network;
@property (nonatomic) id <DSEVocoderDriver> vocoder;
@property (nonatomic, readonly) DSAudioHandler *audio;
@property (nonatomic, readonly) DSESlowDataCoder *slowData;
@property (nonatomic) NSObject <DSEDataEngineDelegate> *delegate;
@property (nonatomic, readonly) NSArray<NSString *> *linkDriverDestinations;
@property AppDelegate *appDelegate;

+(DSEDataEngine *)sharedInstance;

+(void)registerVocoderDriver:(Class)driver;
+(void)registerLinkDriver:(Class)driver;
+(NSArray *)vocoderDrivers;
-(BOOL)isDestinationValid:(NSString *)destination;

-(void)linkTo:(NSString *)reflector;
-(void)unlink;

@end

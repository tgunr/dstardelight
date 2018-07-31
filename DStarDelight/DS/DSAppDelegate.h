
#import <AppKit/AppKit.h>

@class DSReflectors;
@class DSPrefVocoderNetworkViewController;
@interface DSAppDelegate : NSObject <NSApplicationDelegate> {
}

@property DSReflectors *reflectors;

+(DSAppDelegate*)sharedAppdelegate;

@end


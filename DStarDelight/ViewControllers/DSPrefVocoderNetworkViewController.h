
#import <AppKit/AppKit.h>

@class DSEDV3KNetworkVocoder;

typedef enum : NSUInteger {
    undefined,
    stopped,
    started,
} DriverStatus;

@interface DSPrefVocoderNetworkViewController : NSViewController
@property IBOutlet NSTextField *vocoderAddress;
@property IBOutlet NSTextField *vocoderPort;
@property IBOutlet NSTextField *productId;
@property IBOutlet NSTextField *version;
@property IBOutlet NSImageView *statusImageView;
@property (weak) IBOutlet NSTextField *connectionStatus;

@property DSEDV3KNetworkVocoder *driver;

- (void)setStatus: (DriverStatus)status;
@end


#import <AppKit/AppKit.h>

@class DSEDV3KNetworkVocoder;

@interface DSENetworkVocoderViewController : NSViewController

@property (weak) IBOutlet NSTextField *productId;
@property (weak) IBOutlet NSTextField *version;
@property (weak) DSEDV3KNetworkVocoder *driver;

-(IBAction)doTest:(id)sender;
@end

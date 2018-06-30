
#import <AppKit/AppKit.h>

@class DSEDV3KSerialVocoder;

@interface DSESerialVocoderViewController : NSViewController
@property (weak) IBOutlet NSPopUpButton *serialPortPopup;
@property (weak) IBOutlet NSPopUpButton *speedPopup;
@property (weak) IBOutlet NSTextField *productId;
@property (weak) IBOutlet NSTextField *version;
@property (weak) DSEDV3KSerialVocoder *driver;

-(void)refreshDevices;
- (id) init;

- (IBAction) doChangeSerialPort:(id)sender;
- (IBAction) doChangeSpeed:(id)sender;

@end


#import <AppKit/AppKit.h>

#import "DSDV3KSerialVocoder.h"

@interface DSSerialVocoderViewController : NSViewController
@property (weak) IBOutlet NSPopUpButton *serialPortPopup;
@property (weak) IBOutlet NSPopUpButton *speedPopup;
@property (weak) IBOutlet NSTextField *productId;
@property (weak) IBOutlet NSTextField *version;
@property (weak) DSDV3KSerialVocoder *driver;

-(void)refreshDevices;
- (id) init;

- (IBAction) doChangeSerialPort:(id)sender;
- (IBAction) doChangeSpeed:(id)sender;

@end

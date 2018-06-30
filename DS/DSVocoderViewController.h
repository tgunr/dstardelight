
#import <AppKit/AppKit.h>

@interface DSEVocoderViewController : NSViewController
@property (weak) IBOutlet NSPopUpButton *vocoderType;

- (IBAction)selectVocoder:(id)sender;
@end


#import <AppKit/AppKit.h>

@interface DSPrefVocoderViewController : NSTabViewController
@property (weak) IBOutlet NSPopUpButton *vocoderType;

- (IBAction)selectVocoder:(id)sender;
@end

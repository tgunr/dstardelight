
#import <AppKit/AppKit.h>
 
@interface DSEAddPopupController : NSViewController <NSControlTextEditingDelegate, NSPopoverDelegate>

@property (nonatomic) NSArrayController *reflectorArrayController;
@property (weak) IBOutlet NSTextFieldCell *destinationField;
@property (weak) IBOutlet NSPopUpButton *moduleField;

- (IBAction)doAdd:(id)sender;

@end

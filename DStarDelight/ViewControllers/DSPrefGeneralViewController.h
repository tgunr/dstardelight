
#import <AppKit/AppKit.h>

@class MASShortcut, MASShortcutView;

@interface DSPrefGeneralViewController : NSViewController
@property (weak) IBOutlet NSTextField *myCall;
@property (weak) IBOutlet NSTextField *strokeSign;
@property (weak) IBOutlet NSTextField *dataMessage;

@property (nonatomic, weak) IBOutlet MASShortcutView *shortcutView;
@property (nonatomic) MASShortcut *shortcutValue;
@end

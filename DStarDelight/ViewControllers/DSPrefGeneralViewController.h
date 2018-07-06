
#import <AppKit/AppKit.h>

@class MASShortcut, MASShortcutView;

@interface DSPrefGeneralViewController : NSViewController

@property (nonatomic, weak) IBOutlet MASShortcutView *shortcutView;
@property (nonatomic) MASShortcut *shortcutValue;
@end

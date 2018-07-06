

#import "DSPrefGeneralViewController.h"

#import "MASDictionaryTransformer.h"
#import "MASShortcut.h"
#import "MASShortcutView.h"

@interface DSPrefGeneralViewController ()
@end

@implementation DSPrefGeneralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.shortcutView bind:@"shortcutValue" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.shortcutValue" options:@{NSValueTransformerNameBindingOption: MASDictionaryTransformerName}];
}

@end

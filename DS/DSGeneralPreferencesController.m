

#import "DSGeneralPreferencesController.h"

#import "MASDictionaryTransformer.h"
#import "MASShortcut.h"
#import "MASShortcutView.h"

@interface DSEGeneralPreferencesController ()
@end

@implementation DSEGeneralPreferencesController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.shortcutView bind:@"shortcutValue" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.shortcutValue" options:@{NSValueTransformerNameBindingOption: MASDictionaryTransformerName}];
}

@end

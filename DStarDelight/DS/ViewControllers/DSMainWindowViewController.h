
#import <AppKit/AppKit.h>

#import "DSEDataEngineDelegate.h"

@class MASShortcut;

@interface DSEMainWindowViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, NSControlTextEditingDelegate, DSEDataEngineDelegate>

@property (nonatomic, strong) IBOutlet NSArrayController *heardTableController;
@property (nonatomic, weak) IBOutlet NSTableView *heardTableView;
@property (nonatomic, weak) IBOutlet NSTableView *reflectorTableView;
@property (nonatomic, strong) IBOutlet NSArrayController *reflectorTableController;
@property (nonatomic, weak) IBOutlet NSImageView *statusLED;
@property (nonatomic, weak) IBOutlet NSButton *txButton;
@property (nonatomic, weak) IBOutlet NSTextField *repeaterInfo;
@property (nonatomic, readonly) NSMutableArray <NSMutableDictionary *> *qsoList;
@property MASShortcut *txKeyCode;
@property (weak) IBOutlet NSSlider *volumeSlider;


- (IBAction)doReflectorDoubleClick:(id)sender;
- (IBAction)doHeardDoubleClick:(id)sender;
- (IBAction)doLink:(id)sender;
- (IBAction)addReflector:(id)sender;
- (IBAction)doTx:(id)sender;
- (IBAction)doUnlink:(id)sender;
- (IBAction)doVolumeChange:(id)sender;

@end


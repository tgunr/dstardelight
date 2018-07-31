
#import <AppKit/AppKit.h>
#import <ProgressKit/ProgressKit-Swift.h>

#import "DSEDataEngineDelegate.h"

@class MASShortcut;

@interface QSOCQViewController : NSTabViewController <NSTableViewDelegate, NSTableViewDataSource, NSControlTextEditingDelegate, DSEDataEngineDelegate>

@property (nonatomic, strong) IBOutlet NSArrayController *heardTableController;
@property (nonatomic, weak) IBOutlet NSTableView *heardTableView;
@property (nonatomic, weak) IBOutlet NSImageView *statusLED;
@property (nonatomic, weak) IBOutlet NSButton *txButton;
@property (nonatomic, weak) IBOutlet NSTextField *repeaterInfo;
@property (nonatomic, readonly) NSMutableArray <NSMutableDictionary *> *qsoList;
@property MASShortcut *txKeyCode;
@property (weak) IBOutlet NSSlider *volumeSlider;
@property (weak) IBOutlet NSPopUpButton *reflectorPopup;
@property (weak) IBOutlet NSButton *connectReflector;


//- (IBAction)doHeardDoubleClick:(id)sender;
//- (IBAction)doLink:(id)sender;
- (IBAction)doTx:(id)sender;
//- (IBAction)doUnlink:(id)sender;
- (IBAction)doVolumeChange:(id)sender;
- (IBAction)reflectorChanged:(id)sender;
- (IBAction)connectReflector:(NSButton *)sender;

- (void)destinationDidConnect:(NSString *)destination;

- (void)destinationDidError:(NSString *)destination error:(NSError *)error;

- (void)destinationDidLink:(NSString *)destination;

- (void)destinationDidUnlink:(NSString *)destination;

- (void)destinationWillLink:(NSString *)destination;

- (void)locationReceived:(CLLocation *)location forStreamId:(NSNumber *)streamId;

- (void)slowDataReceived:(NSString *)slowData forStreamId:(NSNumber *)streamId;

- (void)streamDidEnd:(NSNumber *)streamId atTime:(NSDate *)date;

- (void)reflectorsAreReady;

- (void)streamDidStart:(NSDictionary *)header;

- (BOOL)commitEditingAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder;

-(void)resetColorForRowView:(NSTableRowView *)rowView atRow:(NSUInteger)row;
@end


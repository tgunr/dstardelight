
#import <AppKit/AppKit.h>

@interface DSPrefAudioViewController : NSViewController
@property (nonatomic, weak) IBOutlet NSPopUpButton *outputDeviceMenu;
@property (nonatomic, weak) IBOutlet NSPopUpButton *inputDeviceMenu;

@property (nonatomic) NSInteger selectedInput;
@property (nonatomic) NSInteger selectedOutput;
@property (nonatomic) BOOL courtesyTone;
@property (nonatomic) BOOL voiceAnnounceOnStatusChange;
@end

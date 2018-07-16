

#import "DSAppDelegate.h"
#import "DSAudioHandler.h"
#import "DStarUtils.h"
#import "DSReflectors.h"
#import <AutoCoding/AutoCoding.h>

@interface DSAppDelegate ()
- (void)reflectorsAreReady:(NSNotification *)notification;
@end

@implementation DSAppDelegate

+(DSAppDelegate*)sharedAppdelegate
{
    return (DSAppDelegate*)[[NSApplication sharedApplication] delegate];
}

-(void) awakeFromNib {
    DSAudioHandler *audioHandler = [DSAudioHandler new];
    [[DSVars shared] setAudioHandler:audioHandler];

    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs =
    [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reflectorsAreReady:) name:@"reflectorsAreReady" object:nil];
    self.reflectors = [DSReflectors new];
}

- (void)reflectorsAreReady: (NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"reflectorsAreReady" object:nil];

}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    
    DSEDataEngine *engine = [DSEDataEngine sharedInstance];
    [engine.slowData bind:@"message" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.slowDataMessage" options:nil];
    
    NSString *inputUid = [[NSUserDefaults standardUserDefaults] stringForKey:@"inputAudioDevice"];
    if(!inputUid) {
        engine.audio.inputDevice = engine.audio.defaultInputDevice;
    } else {
        for(NSDictionary *entry in [DSAudioHandler enumerateInputDevices])
            if([entry[@"uid"] isEqualToString:inputUid])
                engine.audio.inputDevice = (AudioDeviceID) ((NSNumber *)entry[@"id"]).intValue;
     }
    
    NSString *outputUid = [[NSUserDefaults standardUserDefaults] stringForKey:@"outputAudioDevice"];
    if(!outputUid) {
        engine.audio.outputDevice = engine.audio.defaultOutputDevice;
    } else {
        for(NSDictionary *entry in [DSAudioHandler enumerateOutputDevices])
            if([entry[@"uid"] isEqualToString:outputUid])
                engine.audio.outputDevice = (AudioDeviceID) ((NSNumber *)entry[@"id"]).intValue;
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName: DSAudioDeviceChanged
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *notification) {
                                                      for(NSDictionary *entry in [DSAudioHandler enumerateInputDevices]) {
                                                          if(((NSNumber *)entry[@"id"]).intValue == engine.audio.inputDevice) {
                                                              [[NSUserDefaults standardUserDefaults] setObject:entry[@"uid"] forKey:@"inputAudioDevice"];
                                                          }
                                                      }
                                                      
                                                      for(NSDictionary *entry in [DSAudioHandler enumerateOutputDevices]) {
                                                          if(((NSNumber *)entry[@"id"]).intValue == engine.audio.outputDevice) {
                                                              [[NSUserDefaults standardUserDefaults] setObject:entry[@"uid"] forKey:@"outputAudioDevice"];
                                                          }
                                                      }
                                                  }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [engine.audio start];
        engine.audio.outputVolume = [[NSUserDefaults standardUserDefaults] floatForKey:@"outputVolume"];
        
        [engine.vocoder start];
    });
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

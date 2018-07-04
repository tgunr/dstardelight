

#import "DSAppDelegate.h"
#import <DStarEngine/DStarEngine.h>
#import "DSAudioHandler.h"

@implementation DSEAppDelegate

-(void) awakeFromNib {
    DSAudioHandler *audioHandler = [[DSAudioHandler alloc] init];
    [[DSVars shared] setAudioHandler:audioHandler];

    
    NSURL *defaultPrefsFile = [[NSBundle mainBundle]
                               URLForResource:@"DefaultPreferences" withExtension:@"plist"];
    NSDictionary *defaultPrefs =
    [NSDictionary dictionaryWithContentsOfURL:defaultPrefsFile];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    
    DSEDataEngine *engine = [DSEDataEngine sharedInstance];
    [engine.slowData bind:@"message" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.slowDataMessage" options:nil];
    
    NSString *inputUid = [[NSUserDefaults standardUserDefaults] stringForKey:@"inputAudioDevice"];
    DSAudioHandler *engineaudio = (DSAudioHandler *)[DSEDataEngine sharedInstance].audio;
    if(!inputUid) {
        engineaudio.inputDevice = engineaudio.defaultInputDevice;
    } else {
        for(NSDictionary *entry in [DSAudioHandler enumerateInputDevices])
            if([entry[@"uid"] isEqualToString:inputUid])
                engineaudio.inputDevice = ((NSNumber *)entry[@"id"]).intValue;
     }
    
    NSString *outputUid = [[NSUserDefaults standardUserDefaults] stringForKey:@"outputAudioDevice"];
    if(!outputUid) {
        engineaudio.outputDevice = engineaudio.defaultOutputDevice;
    } else {
        for(NSDictionary *entry in [DSAudioHandler enumerateOutputDevices])
            if([entry[@"uid"] isEqualToString:outputUid])
                engineaudio.outputDevice = ((NSNumber *)entry[@"id"]).intValue;
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName: DSAudioDeviceChanged
                                                      object: nil
                                                       queue: [NSOperationQueue mainQueue]
                                                  usingBlock: ^(NSNotification *notification) {
                                                      for(NSDictionary *entry in [DSAudioHandler enumerateInputDevices]) {
                                                          if(((NSNumber *)entry[@"id"]).intValue == engineaudio.inputDevice) {
                                                              [[NSUserDefaults standardUserDefaults] setObject:entry[@"uid"] forKey:@"inputAudioDevice"];
                                                          }
                                                      }
                                                      
                                                      for(NSDictionary *entry in [DSAudioHandler enumerateOutputDevices]) {
                                                          if(((NSNumber *)entry[@"id"]).intValue == engineaudio.outputDevice) {
                                                              [[NSUserDefaults standardUserDefaults] setObject:entry[@"uid"] forKey:@"outputAudioDevice"];
                                                          }
                                                      }
                                                  }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [engineaudio start];
        engineaudio.outputVolume = [[NSUserDefaults standardUserDefaults] floatForKey:@"outputVolume"];

        BOOL started = [engine.vocoder start];
    });
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

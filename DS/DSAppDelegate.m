

#import "DSAppDelegate.h"

#import <DStarEngine/DSEDataEngine.h>
#import "DSDV3KSerialVocoder.h"
#import <DStarEngine/DSESlowDataCoder.h>
#import "DSAudioHandler.h"
#import <Objection/Objection.h>

@interface DSEAppDelegate () 
@end

@implementation DSEAppDelegate

-(void) awakeFromNib {
    
    JSObjectionInjector *injector = [JSObjection createInjector];
    [JSObjection setDefaultInjector:injector];

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
        
        if(![engine.vocoder start])
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                alert.alertStyle = NSAlertStyleWarning;
                alert.messageText = @"Cannot Open the Serial Port";
                alert.informativeText = @"Please check your serial port and speed settings in the Preferences menu";
                [alert runModal];
            });
    });    
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end

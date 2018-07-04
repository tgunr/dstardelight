
#import <AudioToolbox/AudioToolbox.h>
#import "DSEAudioHandler.h"

extern NSString * const DSAudioDeviceChanged;

@protocol DSEVocoderDriver;

@interface DSAudioHandler : DSEAudioHandler

-(BOOL) start;
-(void) stop;

+(NSArray *)enumerateInputDevices;

- (void)setDefaultInputDevice:(id)defaultInputDevice;

+(NSArray *)enumerateOutputDevices;

@end

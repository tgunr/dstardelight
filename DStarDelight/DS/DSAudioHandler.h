
#import <AudioToolbox/AudioToolbox.h>
#import "DSAudioHandler.h"

extern NSString * const DSAudioDeviceChanged;

@protocol DSEVocoderDriver;

extern NSString * const AudioDeviceChanged;
static inline BOOL CheckStatus(OSStatus error, const char *operation);

@interface DSAudioHandler : NSObject

@property (nonatomic) AudioDeviceID inputDevice;
@property (nonatomic) AudioDeviceID outputDevice;
@property (nonatomic) id<DSEVocoderDriver> vocoder;
@property (nonatomic) BOOL receiving;
@property (nonatomic) BOOL xmit;

@property id delegate;

-(void) setOutputVolume:(float)outputVolume;
-(float) outputVolume;
-(void) setInputDevice:(AudioDeviceID)inputDevice;
-(void) setOutputDevice:(AudioDeviceID)outputDevice;
-(void) setInputDevice:(AudioDeviceID)_inputDevice andOutputDevice:(AudioDeviceID)_outputDevice;
-(void) setXmit:(BOOL)xmit;
-(void) setReceiving:(BOOL)receiving;
-(UInt32) defaultOutputDevice;
-(UInt32) defaultInputDevice;
-(void) queueAudioData:(void *)audioData withLength:(AudioDeviceID)length;
-(BOOL) start;
-(void) stop;
+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope;

+(NSArray *)enumerateInputDevices;

-(void)setDefaultInputDevice:(id)defaultInputDevice;

+(NSArray *)enumerateOutputDevices;

@end

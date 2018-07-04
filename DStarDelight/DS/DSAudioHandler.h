
#import <AudioToolbox/AudioToolbox.h>
#import "DSAudioHandler.h"

extern NSString * const DSAudioDeviceChanged;

@protocol DSEVocoderDriver;

extern NSString * const AudioDeviceChanged;
static inline BOOL CheckStatus(OSStatus error, const char *operation);

@interface DSAudioHandler : NSObject

@property (nonatomic) UInt32 inputDevice;
@property (nonatomic) UInt32 outputDevice;
@property (nonatomic) id<DSEVocoderDriver> vocoder;
@property (nonatomic) BOOL receiving;
@property (nonatomic) BOOL xmit;

@property id delegate;

-(void) setOutputVolume:(float)outputVolume;
-(float) outputVolume;
-(void) setInputDevice:(UInt32)inputDevice;
-(void) setOutputDevice:(UInt32)outputDevice;
-(void) setInputDevice:(UInt32)_inputDevice andOutputDevice:(UInt32)_outputDevice;
-(void) setXmit:(BOOL)xmit;
-(void) setReceiving:(BOOL)receiving;
-(UInt32) defaultOutputDevice;
-(UInt32) defaultInputDevice;
-(void) queueAudioData:(void *)audioData withLength:(UInt32)length;
-(BOOL) start;
-(void) stop;
+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope;

+(NSArray *)enumerateInputDevices;

-(void)setDefaultInputDevice:(id)defaultInputDevice;

+(NSArray *)enumerateOutputDevices;

@end

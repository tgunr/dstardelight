
#import <AudioToolbox/AudioToolbox.h>
#import <DStarEngine/DStarEngine.h>

extern NSString * const DSAudioDeviceChanged;

@protocol DSEVocoderDriver;

@interface DSAudioHandler : DSEAudioHandler
//@property (nonatomic) id<DSEVocoderDriver> vocoder;
//@property (nonatomic) AudioDeviceID inputDevice;
//@property (nonatomic) AudioDeviceID outputDevice;
//@property (nonatomic, readonly) AudioDeviceID defaultInputDevice;
//@property (nonatomic, readonly) AudioDeviceID defaultOutputDevice;
//@property (nonatomic) BOOL xmit;
//@property (nonatomic) float outputVolume;

-(void) queueAudioData:(void *)audioData withLength:(UInt32)length;

-(BOOL) start;
-(void) stop;

+(NSArray *)enumerateInputDevices;
+(NSArray *)enumerateOutputDevices;

-(void)setInputDevice:(AudioDeviceID)_inputDevice andOutputDevice:(AudioDeviceID)_outputDevice;

+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope;
@end

#import <AudioToolbox/AudioToolbox.h>
#import <DStarEngine/STUBAudioHandler.h>

@protocol BTRVocoderDriver;

extern NSString * const DSAudioDeviceChanged;

@interface DSAudioHandler : STUBAudioHandler
//@property (nonatomic) id<BTRVocoderDriver> vocoder;
@property (nonatomic) AudioDeviceID inputDevice;
@property (nonatomic) AudioDeviceID outputDevice;
@property (nonatomic, readonly) AudioDeviceID defaultInputDevice;
@property (nonatomic, readonly) AudioDeviceID defaultOutputDevice;
@property (nonatomic) BOOL xmit;
@property (nonatomic) float outputVolume;
//@property (nonatomic) BOOL receiving;

-(void) queueAudioData:(void *)audioData withLength:(UInt32)length;

-(BOOL) start;
-(void) stop;

+(NSArray *)enumerateInputDevices;
+(NSArray *)enumerateOutputDevices;

-(void)setInputDevice:(AudioDeviceID)_inputDevice andOutputDevice:(AudioDeviceID)_outputDevice;

+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope;
@end

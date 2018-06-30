#import <AudioToolbox/AudioToolbox.h>

@protocol BTRVocoderDriver;

extern NSString * const BTRAudioDeviceChanged;

@interface STUBAudioHandler : NSObject

-(void) queueAudioData:(void *)audioData withLength:(UInt32)length;
-(BOOL) start;
-(void) stop;

+(NSArray *)enumerateInputDevices;
+(NSArray *)enumerateOutputDevices;

-(void)setInputDevice:(id)_inputDevice andOutputDevice:(id)_outputDevice;

@property (nonatomic) id<BTRVocoderDriver> vocoder;
@property (nonatomic) id inputDevice;
@property (nonatomic) id outputDevice;
@property (nonatomic, readonly) id defaultInputDevice;
@property (nonatomic, readonly) id defaultOutputDevice;
@property (nonatomic) BOOL xmit;
@property (nonatomic) float outputVolume;

@property (nonatomic) BOOL receiving;

@end

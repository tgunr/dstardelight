#import <AudioToolbox/AudioToolbox.h>

@protocol BTRVocoderDriver;

extern NSString * const AudioDeviceChanged;

@interface STUBAudioHandler : NSObject

@property id delegate;

-(void) queueAudioData:(void *)audioData withLength:(UInt32)length;
-(void)setInputDevice:(id)_inputDevice andOutputDevice:(id)_outputDevice;

@property (nonatomic) id<BTRVocoderDriver> vocoder;
@property (nonatomic) BOOL receiving;

+(NSArray *)enumerateDevices:(id)scope;
@end

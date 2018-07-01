//
//  STUBAudioHandler.h
//

#import <AudioToolbox/AudioToolbox.h>
#import "DSEVocoderDriver.h"

@protocol DSEVocoderDriver;

extern NSString * const AudioDeviceChanged;
static inline BOOL CheckStatus(OSStatus error, const char *operation);

@interface STUBAudioHandler : NSObject

@property (nonatomic) UInt32 inputDevice;
@property (nonatomic) UInt32 outputDevice;
@property (nonatomic) id<DSEVocoderDriver> vocoder;
@property (nonatomic) BOOL receiving;

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
+(NSArray *)enumerateDevices:(id)scope;
@end

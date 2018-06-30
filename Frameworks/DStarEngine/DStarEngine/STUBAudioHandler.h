#import <AudioToolbox/AudioToolbox.h>

@protocol DSEVocoderDriver;

extern NSString * const AudioDeviceChanged;
static inline BOOL CheckStatus(OSStatus error, const char *operation);

@interface STUBAudioHandler : NSObject

@property (nonatomic) id inputDevice;
@property (nonatomic) id outputDevice;
@property (nonatomic) id<DSEVocoderDriver> vocoder;
@property (nonatomic) BOOL receiving;
@property id delegate;

-(void) queueAudioData:(void *)audioData withLength:(UInt32)length;
-(BOOL) start;
-(void) stop;
-(void)setInputDevice:(id)_inputDevice andOutputDevice:(id)_outputDevice;
+(NSArray *)enumerateDevices:(id)scope;
@end

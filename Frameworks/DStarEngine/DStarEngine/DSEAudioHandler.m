//
//  DSEAudioHandler.m
//

#import "DSEAudioHandler.h"

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "DSEVocoderDriver.h"
#import "DSELinkDriverProtocol.h"
#import <Objection/Objection.h>

static const AudioComponentDescription componentDescription = {
    .componentType = kAudioUnitType_Output,
//    .componentSubType = kAudioUnitSubType_HALOutput,
    .componentManufacturer = kAudioUnitManufacturer_Apple,
    .componentFlags = 0,
    .componentFlagsMask = 0
};

static const AudioStreamBasicDescription outputFormat  = {
    .mSampleRate = 8000.0,
    .mFormatID = kAudioFormatLinearPCM,
    .mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger,
    .mBytesPerPacket = sizeof(int16_t),
    .mBytesPerFrame = sizeof(int16_t),
    .mFramesPerPacket = 1,
    .mChannelsPerFrame = 1,
    .mBitsPerChannel = sizeof(int16_t) * 8
};

NSString * const AudioDeviceChanged = @"AudioDeviceChanged";

static inline BOOL CheckStatus(OSStatus error, const char *operation) {
    if(error == noErr)
        return YES;
    
    char str[20] = "";
    // see if it appears to be a 4-char-code
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(str, "%d", (int)error);
    }
    
    switch(error) {
        case kAudioUnitErr_InvalidProperty:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidProperty", operation, str);
            break;
            
        case kAudioUnitErr_InvalidParameter:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidParameter", operation, str);
            break;
            
        case kAudioUnitErr_InvalidElement:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidElement", operation, str);
            break;
            
        case kAudioUnitErr_NoConnection:
            NSLog(@"Error: %s (%s) kAudioUnitErr_NoConnection", operation, str);
            break;
            
        case kAudioUnitErr_FailedInitialization:
            NSLog(@"Error: %s (%s) kAudioUnitErr_FailedInitialization", operation, str);
            break;
            
        case kAudioUnitErr_TooManyFramesToProcess:
            NSLog(@"Error: %s (%s) kAudioUnitErr_TooManyFramesToProcess", operation, str);
            break;
            
        case kAudioUnitErr_InvalidFile:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidFile", operation, str);
            break;
            
        case kAudioUnitErr_FormatNotSupported:
            NSLog(@"Error: %s (%s) kAudioUnitErr_FormatNotSupported", operation, str);
            break;
            
        case kAudioUnitErr_Uninitialized:
            NSLog(@"Error: %s (%s) kAudioUnitErr_Uninitialized", operation, str);
            break;
            
        case kAudioUnitErr_InvalidScope:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidScope", operation, str);
            break;
            
        case kAudioUnitErr_PropertyNotWritable:
            NSLog(@"Error: %s (%s) kAudioUnitErr_PropertyNotWritable", operation, str);
            break;
            
        case kAudioUnitErr_InvalidPropertyValue:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidPropertyValue", operation, str);
            break;
            
        case kAudioUnitErr_PropertyNotInUse:
            NSLog(@"Error: %s (%s) kAudioUnitErr_PropertyNotInUse", operation, str);
            break;
            
        case kAudioUnitErr_Initialized:
            NSLog(@"Error: %s (%s) kAudioUnitErr_Initialized", operation, str);
            break;
            
        case kAudioUnitErr_InvalidOfflineRender:
            NSLog(@"Error: %s (%s) kAudioUnitErr_InvalidOfflineRender", operation, str);
            break;
            
        case kAudioUnitErr_Unauthorized:
            NSLog(@"Error: %s (%s) kAudioUnitErr_Unauthorized", operation, str);
            break;
        default:
            NSLog(@"Error: %s (%s)", operation, str);
            break;
    }
    
    return NO;
}

@interface DSEAudioHandler () {
    AudioUnit outputUnit;
    dispatch_source_t inputAudioSource;
    AudioConverterRef inputConverter;
    
    enum {
        AUDIO_STATUS_STARTED,
        AUDIO_STATUS_STOPPED
    } status;
}

@property (nonatomic, readwrite) AudioDeviceID defaultInputDevice;
@property (nonatomic, readwrite) AudioDeviceID defaultOutputDevice;
@property (nonatomic, readonly) TPCircularBuffer *recordBuffer;
@property (nonatomic, readonly) TPCircularBuffer *playbackBuffer;
@property (nonatomic, readonly) AudioStreamBasicDescription *inputFormat;
@property (nonatomic, readonly) AudioUnit inputUnit;
@property (nonatomic) double hardwareSampleRate;
@end

@implementation DSEAudioHandler

-(void)setOutputVolume:(float)outputVolume {
    if(!outputUnit)
        return;

    if(!CheckStatus(AudioUnitSetParameter(outputUnit, kHALOutputParam_Volume, kAudioUnitScope_Global, 0, outputVolume, 0), "AudioUnitSetParameter(kHALOutputParam_Volume)"))
        return;
}

-(float)outputVolume {
    if(!outputUnit)
        return 0.0;

    float volume;

    if(!CheckStatus(AudioUnitGetParameter(outputUnit, kHALOutputParam_Volume, kAudioUnitScope_Global, 0, &volume), "AudioUnitGetParameter(kHALOutputParam_Volume)")) {
        return 0.0;
    }

    return volume;
}

-(void) setInputDevice:(UInt32)inputDevice {
    if(self.inputDevice == inputDevice)
        return;

    self.inputDevice = inputDevice;

    if(status == AUDIO_STATUS_STARTED) {
        [self stop];
        [self start];
    }
}

-(void) setOutputDevice:(UInt32)outputDevice {
    if(self.outputDevice == outputDevice)
        return;

    self.outputDevice = outputDevice;

    if(status == AUDIO_STATUS_STARTED) {
        [self stop];
        [self start];
    }
}

-(void) setInputDevice:(UInt32)inputDevice andOutputDevice:(UInt32)outputDevice {
    if(_inputDevice == inputDevice && _outputDevice == outputDevice)
        return;

    _inputDevice = inputDevice;
    _outputDevice = outputDevice;

    if(status == AUDIO_STATUS_STARTED) {
        [self stop];
        [self start];
    }
}

- (void) setXmit:(BOOL)xmit {
 
    NSAssert(NO, @"The method %@ in %@ must be overridden.",
             NSStringFromSelector(_cmd), NSStringFromClass([self class]));
    
    NSLog(@"The method playbackThreadCallback in AudioHandler must be overridden.");
    NSError * unimp = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    @throw unimp;
}

-(void)setReceiving:(BOOL)receiving {
    _receiving = receiving;

    if(receiving)
        TPCircularBufferClear(self.playbackBuffer);
}

-(UInt32) defaultOutputDevice {
    AudioObjectPropertyAddress propertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
    id device;

    UInt32 deviceSize = sizeof(device);
    if(!CheckStatus(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &deviceSize, &device), "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultOutputDevice)"))
        return 0;

    return device;
}

-(UInt32) defaultInputDevice {
    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster };
    AudioDeviceID device;

    UInt32 deviceSize = sizeof(device);
    OSStatus stat = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &deviceSize, &device);
    if(!CheckStatus(stat, "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultInputDevice"))
        return 0;

    return device;
}

-(void) queueAudioData:(void *)audioData withLength:(UInt32)length {
    if(TPCircularBufferProduceBytes(self.playbackBuffer, audioData, length) == false) {
        NSLog(@"No space left in buffer\n");
    }
}

-(BOOL) start {

    NSAssert(NO, @"The method %@ in %@ must be overridden.",
             NSStringFromSelector(_cmd), NSStringFromClass([self class]));

    NSLog(@"The method playbackThreadCallback in AudioHandler must be overridden.");
    NSError * unimp = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    @throw unimp;
    return unimpErr;

}

-(void) stop {
    if(status != AUDIO_STATUS_STARTED)
        return;

    NSLog(@"Stopping audio");

    if(inputConverter) {
        AudioConverterDispose(inputConverter);
        inputConverter = NULL;
    }

    status = AUDIO_STATUS_STOPPED;
}

+(NSArray *) enumerateDevices:(id)scope {
    NSAssert(NO, @"The method %@ in %@ must be overridden.",
             NSStringFromSelector(_cmd), NSStringFromClass([self class]));
    return NULL;
}

@end


#import "STUBAudioHandler.h"

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
//#import "BTRVocoderDriver.h"
//#import "BTRLinkDriverProtocol.h"

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

NSString * const BTRAudioDeviceChanged = @"BTRAudioDeviceChanged";

static inline BOOL CheckStatus(OSStatus error, const char *operation);

@interface STUBAudioHandler () {
    AudioUnit outputUnit;
    dispatch_source_t inputAudioSource;
    AudioConverterRef inputConverter;
    
    enum {
        AUDIO_STATUS_STARTED,
        AUDIO_STATUS_STOPPED
    } status;
}

//@property (nonatomic, readwrite) AudioDeviceID defaultInputDevice;
//@property (nonatomic, readwrite) AudioDeviceID defaultOutputDevice;

@property (nonatomic, readonly) TPCircularBuffer *recordBuffer;
@property (nonatomic, readonly) TPCircularBuffer *playbackBuffer;

@property (nonatomic, readonly) AudioStreamBasicDescription *inputFormat;
@property (nonatomic, readonly) AudioUnit inputUnit;

@property (nonatomic) double hardwareSampleRate;

//+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope;
@end

static OSStatus playbackThreadCallback (void *userData, AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    int32_t availableBytes;
    void *bufferTail;
    STUBAudioHandler *self = (__bridge STUBAudioHandler *) userData;
    
    for(unsigned int i = 0; i < ioData->mNumberBuffers; ++i) {
        bufferTail = TPCircularBufferTail(self.playbackBuffer, &availableBytes);
        if((UInt32) availableBytes < ioData->mBuffers[i].mDataByteSize) {
            memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
            if(!self.receiving && availableBytes > 0) {
                memcpy(ioData->mBuffers[i].mData, bufferTail, availableBytes);
                TPCircularBufferConsume(self.playbackBuffer, availableBytes);
            }
        } else {
            memcpy(ioData->mBuffers[i].mData, bufferTail, ioData->mBuffers[i].mDataByteSize);
            TPCircularBufferConsume(self.playbackBuffer, ioData->mBuffers[i].mDataByteSize);
        }
    }
    
    return noErr;
}

//static OSStatus recordThreadCallback (void *userData, AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
//    STUBAudioHandler *audioHandler = (__bridge STUBAudioHandler *) userData;
//
//    OSStatus error;
//
//    AudioBufferList *bufferList = TPCircularBufferPrepareEmptyAudioBufferListWithAudioFormat(audioHandler.recordBuffer, audioHandler.inputFormat, inNumberFrames, inTimeStamp);
//    if(!bufferList) {
//        NSLog(@"recordBuffer is full");
//        return kIOReturnSuccess;
//    }
//
//    error = AudioUnitRender(audioHandler.inputUnit, actionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList);
//    if(error != noErr) {
//        NSLog(@"Error rendering input audio %d\n", error);
//    }
//
//    if(audioHandler.xmit)
//        TPCircularBufferProduceAudioBufferList(audioHandler.recordBuffer, inTimeStamp);
//
//    return kIOReturnSuccess;
//}

//static OSStatus audioConverterCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
//    STUBAudioHandler *audioHandler = (__bridge STUBAudioHandler *) inUserData;
//    AudioTimeStamp timestamp;
//
//    ioData->mNumberBuffers = 1;
//    ioData->mBuffers[0].mNumberChannels = 1;
//    ioData->mBuffers[0].mDataByteSize = *ioNumberDataPackets * sizeof(short);
//    ioData->mBuffers[0].mData = calloc(1, ioData->mBuffers[0].mDataByteSize);
//
//    TPCircularBufferDequeueBufferListFrames(audioHandler.recordBuffer, ioNumberDataPackets, ioData, &timestamp, audioHandler.inputFormat);
//
//    ioData->mBuffers[0].mDataByteSize = *ioNumberDataPackets * sizeof(short);
//    if(*ioNumberDataPackets == 0)
//        return kAudioConverterErr_UnspecifiedError;
//
//    return noErr;
//}

//static OSStatus AudioDevicesChanged(AudioObjectID inObjectID, UInt32 inNumberAddress, const AudioObjectPropertyAddress inAddresses[], void *inClientData) {
//    STUBAudioHandler *handler = (__bridge STUBAudioHandler *) inClientData;
//    AudioDeviceID inputDevice = handler.inputDevice;
//    AudioDeviceID outputDevice = handler.outputDevice;
//    
//    if(NSNotFound == [[STUBAudioHandler enumerateInputDevices] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){ return ((NSNumber *)((NSDictionary *)obj)[@"id"]).intValue == handler.inputDevice; }])
//        inputDevice = handler.defaultInputDevice;
//    
//    if(NSNotFound == [[STUBAudioHandler enumerateOutputDevices] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){ return ((NSNumber *)((NSDictionary *)obj)[@"id"]).intValue == handler.outputDevice; }])
//        outputDevice = handler.defaultOutputDevice;
//    
//    [handler setInputDevice:inputDevice andOutputDevice:outputDevice];
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:BTRAudioDeviceChanged object: nil];
//    
//    return noErr;
//}


@implementation STUBAudioHandler

- (id) init {
    self = [super init];
    
    if(self) {
        _playbackBuffer = malloc(sizeof(TPCircularBuffer));
        TPCircularBufferInit(_playbackBuffer, 16384);
        
        _recordBuffer = malloc(sizeof(TPCircularBuffer));
        TPCircularBufferInit(_recordBuffer, 16384);
        
        _inputFormat = malloc(sizeof(AudioStreamBasicDescription));
        
        _xmit = NO;
        inputConverter = NULL;
        _inputUnit = NULL;
        outputUnit = NULL;
        
        status = AUDIO_STATUS_STOPPED;
        
        _inputDevice = 0;
        _outputDevice = 0;
        
        _hardwareSampleRate = 0.0;
        
        _receiving = NO;
        
//        AudioObjectPropertyAddress propertyAddress = {
//            kAudioHardwarePropertyDevices,
//            kAudioObjectPropertyScopeGlobal,
//            kAudioObjectPropertyElementMaster
//        };
//        
//        AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, AudioDevicesChanged, (__bridge void *) self);
    }
    
    return self;
}

- (void) dealloc {
    free(_playbackBuffer);
    free(_recordBuffer);
    free(_inputFormat);
}

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

- (void) setInputDevice:(id)inputDevice {
    if(_inputDevice == inputDevice)
        return;
    
    _inputDevice = inputDevice;
    
    if(status == AUDIO_STATUS_STARTED) {
        [self stop];
        [self start];
    }
}

- (void) setOutputDevice:(id)outputDevice {
    if(_outputDevice == outputDevice)
        return;
    
    _outputDevice = outputDevice;
    
    if(status == AUDIO_STATUS_STARTED) {
        [self stop];
        [self start];
    }
}

-(void)setInputDevice:(id)inputDevice andOutputDevice:(id)outputDevice {
    if(_inputDevice == inputDevice && _outputDevice == outputDevice)
        return;
    
    _inputDevice = inputDevice;
    _outputDevice = outputDevice;
    
    if(status == AUDIO_STATUS_STARTED) {
        [self stop];
        [self start];
    }
}


//- (void) setXmit:(BOOL)xmit {
//    if(_xmit == xmit)
//        return;
//
//    if(xmit) {
//        if(inputConverter)
//            AudioConverterReset(inputConverter);
//
//        TPCircularBufferClear(self.recordBuffer);
//
//        inputAudioSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
//        dispatch_source_set_timer(inputAudioSource, dispatch_time(DISPATCH_TIME_NOW, 100ul * NSEC_PER_MSEC), 20ull * NSEC_PER_MSEC, 1ull * NSEC_PER_MSEC);
//
//        STUBAudioHandler __weak *weakSelf = self;
//        dispatch_source_set_event_handler(inputAudioSource, ^{
//            AudioBufferList bufferList;
//            AudioTimeStamp timestamp;
//            UInt32 numSamples = 160;
//            BOOL last = NO;
//
//            bufferList.mNumberBuffers = 1;
//            bufferList.mBuffers[0].mNumberChannels = 1;
//            bufferList.mBuffers[0].mDataByteSize = numSamples * sizeof(short);
//            bufferList.mBuffers[0].mData = calloc(1, bufferList.mBuffers[0].mDataByteSize);
//
//            if(weakSelf.hardwareSampleRate == 8000.0) {
//                TPCircularBufferDequeueBufferListFrames(self.recordBuffer, &numSamples, &bufferList, &timestamp, self.inputFormat);
//            } else {
//                OSStatus error = AudioConverterFillComplexBuffer(self->inputConverter, audioConverterCallback, (__bridge void *)(weakSelf), &numSamples, &bufferList, NULL);
//
//                if(error != noErr && error != kAudioConverterErr_UnspecifiedError) {
//                    NSLog(@"Error in audio converter: %d", error);
//                    return;
//                }
//            }
//
//            if(!weakSelf.xmit && numSamples == 0) {
//                last = YES;
//                dispatch_source_cancel(self->inputAudioSource);
//            }
//
//            [weakSelf.vocoder encodeData:bufferList.mBuffers[0].mData lastPacket:last];
//
//            free(bufferList.mBuffers[0].mData);
//        });
//
//        dispatch_resume(inputAudioSource);
//    }
//    _xmit = xmit;
//}
//
-(void)setReceiving:(BOOL)receiving {
    _receiving = receiving;
    
    if(receiving)
        TPCircularBufferClear(self.playbackBuffer);
}

//- (id) defaultOutputDevice {
//    AudioObjectPropertyAddress propertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
//    id device;
//
//    UInt32 deviceSize = sizeof(device);
//    if(!CheckStatus(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &deviceSize, &device), "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultOutputDevice)"))
//        return 0;
//
//    return device;
//}
//
//- (AudioDeviceID) defaultInputDevice {
//    AudioObjectPropertyAddress propertyAddress = {
//        kAudioHardwarePropertyDefaultInputDevice,
//        kAudioObjectPropertyScopeGlobal,
//        kAudioObjectPropertyElementMaster };
//    AudioDeviceID device;
//
//    UInt32 deviceSize = sizeof(device);
//    OSStatus stat = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &deviceSize, &device);
//    if(!CheckStatus(stat, "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultInputDevice"))
//        return 0;
//
//    return device;
//}
//
//
//-(void) queueAudioData:(void *)audioData withLength:(uint32)length {
//    if(TPCircularBufferProduceBytes(self.playbackBuffer, audioData, length) == false) {
//       // NSLog(@"No space left in buffer\n");
//    }
//
//}

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

-(void)stop {
    if(status != AUDIO_STATUS_STARTED)
        return;
    
    NSLog(@"Stopping audio");
    
    if(inputConverter) {
        AudioConverterDispose(inputConverter);
        inputConverter = NULL;
    }
    
    AudioOutputUnitStop(self.inputUnit);
    AudioOutputUnitStop(outputUnit);
    AudioUnitUninitialize(self.inputUnit);
    AudioUnitUninitialize(outputUnit);
    AudioComponentInstanceDispose(self.inputUnit);
    AudioComponentInstanceDispose(outputUnit);
    _inputUnit = NULL;
    outputUnit = NULL;
    
    status = AUDIO_STATUS_STOPPED;
}


//+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope {
//
//    NSMutableArray *devices = [NSMutableArray arrayWithCapacity:1];
//    
//    NSParameterAssert(scope == kAudioObjectPropertyScopeOutput ||
//                      scope == kAudioObjectPropertyScopeInput);
//    
//    [STUBAudioHandler enumerateDevicesWithBlock:^(AudioDeviceID deviceId){
//        NSString *deviceName;
//        NSString *deviceUID;
//        OSStatus status;
//        
//        UInt32 dataSize = sizeof(deviceName);
//        AudioObjectPropertyAddress propertyAddress = {
//            kAudioDevicePropertyDeviceNameCFString,
//            kAudioObjectPropertyScopeGlobal,
//            kAudioObjectPropertyElementMaster
//        };
//
//        status = AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, &deviceName);
//        if(status != kAudioHardwareNoError) {
//            NSLog(@"AudioObjectGetPropertyData (kAudioDevicePropertyDeviceNameCFString) failed");
//            return;
//        }
//        
//        dataSize = sizeof(deviceUID);
//        propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
//        status = AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, &deviceUID);
//        if(status != kAudioHardwareNoError) {
//            NSLog(@"AudioObjectGetPropertyData (kAudioDevicePropertyDeviceNameCFString) failed");
//            return;
//        }
//    
//        //  We have to see if there are any audio buffers for the appropriate scope to see if the device supports
//        //  that scope.
//        propertyAddress.mScope = scope;
//        dataSize = 0;
//        propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
//        status = AudioObjectGetPropertyDataSize(deviceId, &propertyAddress, 0, NULL, &dataSize);
//        if(status != kAudioHardwareNoError) {
//            NSLog(@"AudioObjectGetPropertyDataSize (kAudioDevicePropertyStreamConfiguration) failed");
//            return;
//        }
//    
//        AudioBufferList *bufferList = (AudioBufferList *) malloc(dataSize);
//        if(bufferList == NULL) {
//            NSLog(@"Unable to malloc memory");
//            return;
//        }
//        status = AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, bufferList);
//        // If no buffers, device is not of this scope so free the list and try again
//        if(status != kAudioHardwareNoError || bufferList->mNumberBuffers == 0) {
//            if(status != kAudioHardwareNoError)
//                NSLog(@"AudioObjectGetPropertyData (kAudioDevicePropertyStreamConfiguration) failed");
//            free(bufferList);
//            bufferList = NULL;
//            return;
//        }
//    
//        free(bufferList);
//        bufferList = NULL;
//    
//        [devices addObject: @{ @"description":deviceName, @"uid":deviceUID, @"id":[NSNumber numberWithInt:deviceId] }];
//    }];
//
//    return [NSArray arrayWithArray:devices];
//}
//
@end

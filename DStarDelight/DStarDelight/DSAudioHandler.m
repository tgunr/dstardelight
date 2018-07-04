
#import "DSAudioHandler.h"

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

NSString * const DSAudioDeviceChanged = @"DSAudioDeviceChanged";

static inline BOOL CheckStatus(OSStatus error, const char *operation);

@interface DSAudioHandler () {
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

+ (NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope;
@end

static OSStatus playbackThreadCallback (void *userData, AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    uint32_t availableBytes;
    void *bufferTail;
    DSAudioHandler *self = (__bridge DSAudioHandler *) userData;
    
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

static OSStatus recordThreadCallback (void *userData, AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    DSAudioHandler *audioHandler = (__bridge DSAudioHandler *) userData;

    OSStatus error;

    AudioBufferList *bufferList = TPCircularBufferPrepareEmptyAudioBufferListWithAudioFormat(audioHandler.recordBuffer, audioHandler.inputFormat, inNumberFrames, inTimeStamp);
    if(!bufferList) {
        NSLog(@"recordBuffer is full");
        return kIOReturnSuccess;
    }

    error = AudioUnitRender(audioHandler.inputUnit, actionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList);
    if(error != noErr) {
        NSLog(@"Error rendering input audio %d\n", error);
    }

    if(audioHandler.xmit)
        TPCircularBufferProduceAudioBufferList(audioHandler.recordBuffer, inTimeStamp);

    return kIOReturnSuccess;
}

static OSStatus audioConverterCallback(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    DSAudioHandler *audioHandler = (__bridge DSAudioHandler *) inUserData;
    AudioTimeStamp timestamp;

    ioData->mNumberBuffers = 1;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mDataByteSize = *ioNumberDataPackets * sizeof(short);
    ioData->mBuffers[0].mData = calloc(1, ioData->mBuffers[0].mDataByteSize);

    TPCircularBufferDequeueBufferListFrames(audioHandler.recordBuffer, ioNumberDataPackets, ioData, &timestamp, audioHandler.inputFormat);

    ioData->mBuffers[0].mDataByteSize = *ioNumberDataPackets * sizeof(short);
    if(*ioNumberDataPackets == 0)
        return kAudioConverterErr_UnspecifiedError;

    return noErr;
}

static OSStatus AudioDevicesChanged(AudioObjectID inObjectID, UInt32 inNumberAddress, const AudioObjectPropertyAddress inAddresses[], void *inClientData) {
    DSAudioHandler *handler = (DSAudioHandler *)CFBridgingRelease(inClientData);
    AudioDeviceID inputDevice = handler.inputDevice;
    AudioDeviceID outputDevice = handler.outputDevice;
    
    if(NSNotFound == [[DSAudioHandler enumerateInputDevices] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){ return ((NSNumber *)((NSDictionary *)obj)[@"id"]).intValue == handler.inputDevice; }])
        inputDevice = handler.defaultInputDevice;
    
    if(NSNotFound == [[DSAudioHandler enumerateOutputDevices] indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){ return ((NSNumber *)((NSDictionary *)obj)[@"id"]).intValue == handler.outputDevice; }])
        outputDevice = handler.defaultOutputDevice;
    
    [handler setInputDevice:inputDevice andOutputDevice:outputDevice];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DSAudioDeviceChanged object: nil];
    
    return noErr;
}


@implementation DSAudioHandler

- (id) init {
    self = [super init];

    if(self) {
        _playbackBuffer = malloc(sizeof(TPCircularBuffer));
        TPCircularBufferInit(_playbackBuffer, 16384);

        _recordBuffer = malloc(sizeof(TPCircularBuffer));
        TPCircularBufferInit(_recordBuffer, 16384);

        _inputFormat = malloc(sizeof(AudioStreamBasicDescription));

        self.xmit = NO;
        inputConverter = NULL;
        _inputUnit = NULL;
        outputUnit = NULL;

        status = AUDIO_STATUS_STOPPED;

        self.inputDevice = 0;
        self.outputDevice = 0;
        
        _hardwareSampleRate = 0.0;
        
        
        self.receiving = NO;
        
        AudioObjectPropertyAddress propertyAddress = {
            kAudioHardwarePropertyDevices,
            kAudioObjectPropertyScopeGlobal,
            kAudioObjectPropertyElementMaster
        };
        
        AudioObjectAddPropertyListener(kAudioObjectSystemObject, &propertyAddress, AudioDevicesChanged, (__bridge void *) self);
    }
    
    return self;
}

- (void) dealloc {
    free(_playbackBuffer);
    free(_recordBuffer);
    free(_inputFormat);
}

- (void) setXmit:(BOOL)xmit {
    if(self.xmit == xmit)
        return;

    if(xmit) {
        if(inputConverter)
            AudioConverterReset(inputConverter);

        TPCircularBufferClear(self.recordBuffer);

        inputAudioSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        dispatch_source_set_timer(inputAudioSource, dispatch_time(DISPATCH_TIME_NOW, 100ul * NSEC_PER_MSEC), 20ull * NSEC_PER_MSEC, 1ull * NSEC_PER_MSEC);

        DSAudioHandler __weak *weakSelf = self;
        dispatch_source_set_event_handler(inputAudioSource, ^{
            AudioBufferList bufferList;
            AudioTimeStamp timestamp;
            UInt32 numSamples = 160;
            BOOL last = NO;

            bufferList.mNumberBuffers = 1;
            bufferList.mBuffers[0].mNumberChannels = 1;
            bufferList.mBuffers[0].mDataByteSize = numSamples * sizeof(short);
            bufferList.mBuffers[0].mData = calloc(1, bufferList.mBuffers[0].mDataByteSize);

            if(weakSelf.hardwareSampleRate == 8000.0) {
                TPCircularBufferDequeueBufferListFrames(self.recordBuffer, &numSamples, &bufferList, &timestamp, self.inputFormat);
            } else {
                OSStatus error = AudioConverterFillComplexBuffer(self->inputConverter, audioConverterCallback, (__bridge void *)(weakSelf), &numSamples, &bufferList, NULL);

                if(error != noErr && error != kAudioConverterErr_UnspecifiedError) {
                    NSLog(@"Error in audio converter: %d", error);
                    return;
                }
            }

            if(!weakSelf.xmit && numSamples == 0) {
                last = YES;
                dispatch_source_cancel(self->inputAudioSource);
            }

            [weakSelf.vocoder encodeData:bufferList.mBuffers[0].mData lastPacket:last];

            free(bufferList.mBuffers[0].mData);
        });

        dispatch_resume(inputAudioSource);
    }
    self.xmit = xmit;
}

- (AudioDeviceID) defaultOutputDevice {
    AudioObjectPropertyAddress propertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
    UInt32 device;

    UInt32 deviceSize = sizeof(device);
    if(!CheckStatus(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &deviceSize, &device), "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultOutputDevice)"))
        return 0;

    return device;
}

- (AudioDeviceID) defaultInputDevice {
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

- (BOOL) start {
    AudioComponent outputComponent;
    
    if(status != AUDIO_STATUS_STOPPED)
        return NO;
    
    //  Set up the CoreAudio run loop and find the Output HAL
    CFRunLoopRef runLoop = NULL;
    AudioObjectPropertyAddress theAddress = { kAudioHardwarePropertyRunLoop, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
    CheckStatus(AudioObjectSetPropertyData(kAudioObjectSystemObject, &theAddress, 0, NULL, sizeof(CFRunLoopRef), &runLoop), "AudioObjectSetPropertyData(kAudioHardwarePropertyRunLoop");
    
    outputComponent = AudioComponentFindNext(NULL, &componentDescription);
    
    //  Set up the output unit for speaker output
    if(!CheckStatus(AudioComponentInstanceNew(outputComponent, &outputUnit), "AudioComponentInstanceNew"))
        return NO;
    
    AudioObjectPropertyAddress propertyAddress = { kAudioHardwarePropertyDefaultOutputDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
    
    AudioDeviceID outDevice = self.outputDevice;
    if(self.outputDevice == 0) {
        UInt32 defaultDeviceSize = sizeof(self.outputDevice);
        if(!CheckStatus(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &defaultDeviceSize, &outDevice), "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultOutputDevice)"))
            return NO;
    }
    
    if(!CheckStatus(AudioUnitSetProperty(outputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &outDevice, sizeof(AudioDeviceID)), "AudioUnitSetProperty(kAudioOutputUnitProperty_CurrentDevice)"))
        return NO;
    
    
    if(!CheckStatus(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outputFormat, sizeof(outputFormat)), "AudioUnitSetProperty(kAudioUnitPropertyStreamFormat)"))
        return NO;
    
    AURenderCallbackStruct renderCallback;
    renderCallback.inputProc = playbackThreadCallback;
    renderCallback.inputProcRefCon = (__bridge void *)(self);
    
    if(!CheckStatus(AudioUnitSetProperty(outputUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &renderCallback, sizeof(renderCallback)), "AudioUnitSetProperty(kAudioUnitProperty_SetRenderCallback)"))
        return NO;
    
    if(!CheckStatus(AudioUnitInitialize(outputUnit), "AudioUnitInitialize"))
        return NO;
    
    if(!CheckStatus(AudioOutputUnitStart(outputUnit), "AudioOutputUnitStart"))
        return NO;
    
    //  Set up microphone input audio
    if(!CheckStatus(AudioComponentInstanceNew(outputComponent, &_inputUnit), "AudioComponentInstanceNew"))
        return NO;
    
    UInt32 enable = 1;
    if(!CheckStatus(AudioUnitSetProperty(self.inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enable, sizeof(enable)), "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO"))
        return NO;
    
    enable = 0;
    if(!CheckStatus(AudioUnitSetProperty(self.inputUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &enable, sizeof(enable)), "AudioUnitSetProperty(kAudioOutputUnitProperty_EnableIO"))
        return NO;
    
    propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
    
    AudioDeviceID inDevice = self.inputDevice;
    if(self.inputDevice == 0) {
        AudioDeviceID defaultDeviceSize = sizeof(self.inputDevice);
        if(!CheckStatus(AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &defaultDeviceSize, &inDevice), "AudioUnitGetPropertyData(kAudioHardwarePropertyDefaultInputDevice)"))
            return NO;
    }
    
    if(!CheckStatus(AudioUnitSetProperty(self.inputUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &inDevice, sizeof(AudioDeviceID)), "AudioUnitSetProperty(kAudioOutputUnitProperty_CurrentDevice)"))
        return NO;
    
    renderCallback.inputProc = recordThreadCallback;
    renderCallback.inputProcRefCon = (__bridge void *)(self);
    if(!CheckStatus(AudioUnitSetProperty(self.inputUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &renderCallback, sizeof(renderCallback)), "AudioUnitSetProperty(kAudioOutputUnitProperty_SetInputCallback)"))
        return NO;
    
    int allocBuffer = false;
    if(!CheckStatus(AudioUnitSetProperty(self.inputUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, 1, &allocBuffer, sizeof(allocBuffer)), "AudioUnitSetProperty(kAudioUnitProperty_ShouldAllocateBuffer)"))
        return NO;
    
    //  Need to get the possible hardware rates here to see if we support 8k.  If we don't, we're going to have to resample.
    //  If we have to resample, we'd prefer to set the hardware sample rate to 48k if possible because it will make the
    //  resampling rate integral rather than fractional.
    
    propertyAddress.mSelector = kAudioDevicePropertyAvailableNominalSampleRates;
    UInt32 sampleRatesSize = 0;
    if(!CheckStatus(AudioObjectGetPropertyDataSize(self.inputDevice, &propertyAddress, 0, NULL, &sampleRatesSize), "AudioObjectGetPropertyDataSize(kAudioDevicePropertyAvailableNominalSampleRates"))
        return NO;
    
    AudioValueRange *sampleRateRanges = (AudioValueRange *) malloc(sampleRatesSize);
    
    if(!CheckStatus(AudioObjectGetPropertyData(self.inputDevice, &propertyAddress, 0, NULL, &sampleRatesSize, sampleRateRanges), "AudioObjectGetPropertyData(kAudioDevicePropertyAvailableNominalSampleRates")) {
        free(sampleRateRanges);
        return NO;
    }
    
    for(int i = 0; i < sampleRatesSize / sizeof(AudioValueRange); ++i) {
        NSLog(@"Range %d: Max = %f, Min = %f", i, sampleRateRanges[i].mMaximum, sampleRateRanges[i].mMinimum);
        if(sampleRateRanges[i].mMaximum >= 8000.0 && sampleRateRanges[i].mMinimum <= 8000.0)
            self.hardwareSampleRate = 8000.0;
        if(sampleRateRanges[i].mMinimum >= 48000.0 && sampleRateRanges[i].mMinimum <= 48000.0 && self.hardwareSampleRate != 8000.0)
            self.hardwareSampleRate = 48000.0;
    }
    
    free(sampleRateRanges);
    
    NSLog(@"We want hardware sample rate to be %f\n", self.hardwareSampleRate);
    if(self.hardwareSampleRate != 0.0) {
        propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate;
        AudioValueRange hardwareSampleRateRange = {
            .mMinimum = self.hardwareSampleRate,
            .mMaximum = self.hardwareSampleRate
        };
        if(!CheckStatus(AudioObjectSetPropertyData(self.inputDevice, &propertyAddress, 0, NULL, sizeof(hardwareSampleRateRange), &hardwareSampleRateRange), "AudioObjectSetPropertyData(kAudioDevicePropertyNominalSampleRate)"))
            return NO;
    } else {
        AudioValueRange hardwareSampleRateRange;
        UInt32 rangeSize = sizeof(hardwareSampleRateRange);
        propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate;
        if(!CheckStatus(AudioObjectGetPropertyData(self.inputDevice, &propertyAddress, 0, NULL, &rangeSize, &hardwareSampleRateRange), "AudioObjectGetPropertyData(kAudioDevicePropertyNominalSampleRate"))
            return NO;
        
        self.hardwareSampleRate = hardwareSampleRateRange.mMinimum;
    }
    NSLog(@"We got hardware sample rate to be %f\n", self.hardwareSampleRate);
    
    UInt32 inputFormatSize = sizeof(AudioStreamBasicDescription);
    if(!CheckStatus(AudioUnitGetProperty(self.inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, self.inputFormat, &inputFormatSize), "AudioUnitGetProperty(kAudioUnitProperty_StreamFormat)"))
        return NO;
    
    self.inputFormat->mSampleRate = self.hardwareSampleRate;
    self.inputFormat->mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger| kAudioFormatFlagIsBigEndian;
    self.inputFormat->mBytesPerPacket = sizeof(int16_t);
    self.inputFormat->mBytesPerFrame = sizeof(int16_t);
    self.inputFormat->mFramesPerPacket = 1;
    self.inputFormat->mChannelsPerFrame = 1;
    self.inputFormat->mBitsPerChannel = sizeof(int16_t) * 8;
    
    if(!CheckStatus(AudioUnitSetProperty(self.inputUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, self.inputFormat, sizeof(AudioStreamBasicDescription)), "AudioUnitSetProperty(kAudioUnitProperty_StreamFormat)"))
        return NO;
    
    if(self.hardwareSampleRate != 8000.0)
        AudioConverterNew(self.inputFormat, &outputFormat, &inputConverter);
    
    //  Start everything up.
    
    if(!CheckStatus(AudioUnitInitialize(self.inputUnit), "AudioUnitInitialize"))
        return NO;
    
    if(!CheckStatus(AudioOutputUnitStart(self.inputUnit), "AudioOutputUnitStart"))
        return NO;
    
    NSLog(@"Audio system set up\n");
    
    status = AUDIO_STATUS_STARTED;
    
    return YES;
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

+(NSArray *)enumerateInputDevices {
    return [self enumerateDevices:kAudioObjectPropertyScopeInput];
}

+(NSArray *)enumerateOutputDevices {
    return [self enumerateDevices:kAudioObjectPropertyScopeOutput];
}

+(void)enumerateDevicesWithBlock:(void(^)(AudioDeviceID))enumeratorBlock {
    OSStatus status;
    
    AudioObjectPropertyAddress propertyAddress = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    UInt32 dataSize = 0;
    status = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize);
    if(status != kAudioHardwareNoError) {
        NSLog(@"AudioObjectGetPropertyDataSize (kAudioHardwarePropertyDevices) failed");
        return;
    }
    
    UInt32 deviceCount = (UInt32)(dataSize / sizeof(AudioDeviceID));
    AudioDeviceID *audioDevices = (AudioDeviceID *) malloc(dataSize);
    if(audioDevices == NULL) {
        NSLog(@"Unable to allocate memory");
        return;
    }
    
    status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &dataSize, audioDevices);
    if(status != kAudioHardwareNoError) {
        NSLog(@"AudioObjectGetPropertyData (kAudioHardwarePropertyDevices) failed");
        free(audioDevices);
        return;
    }
    
    for(UInt32 i = 0; i < deviceCount; ++i) {
        enumeratorBlock(audioDevices[i]);
    }
    
    free(audioDevices);
}

+(NSArray *)enumerateDevices:(AudioObjectPropertyScope)scope {

    NSMutableArray *devices = [NSMutableArray arrayWithCapacity:1];
    
    NSParameterAssert(scope == kAudioObjectPropertyScopeOutput ||
                      scope == kAudioObjectPropertyScopeInput);
    
    [DSAudioHandler enumerateDevicesWithBlock:^(AudioDeviceID deviceId){
        NSString *deviceName;
        NSString *deviceUID;
        OSStatus status;
        
        UInt32 dataSize = sizeof(deviceName);
        AudioObjectPropertyAddress propertyAddress = {
            kAudioDevicePropertyDeviceNameCFString,
            kAudioObjectPropertyScopeGlobal,
            kAudioObjectPropertyElementMaster
        };

        status = AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, &deviceName);
        if(status != kAudioHardwareNoError) {
            NSLog(@"AudioObjectGetPropertyData (kAudioDevicePropertyDeviceNameCFString) failed");
            return;
        }
        
        dataSize = sizeof(deviceUID);
        propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
        status = AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, &deviceUID);
        if(status != kAudioHardwareNoError) {
            NSLog(@"AudioObjectGetPropertyData (kAudioDevicePropertyDeviceNameCFString) failed");
            return;
        }
    
        //  We have to see if there are any audio buffers for the appropriate scope to see if the device supports
        //  that scope.
        propertyAddress.mScope = scope;
        dataSize = 0;
        propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
        status = AudioObjectGetPropertyDataSize(deviceId, &propertyAddress, 0, NULL, &dataSize);
        if(status != kAudioHardwareNoError) {
            NSLog(@"AudioObjectGetPropertyDataSize (kAudioDevicePropertyStreamConfiguration) failed");
            return;
        }
    
        AudioBufferList *bufferList = (AudioBufferList *) malloc(dataSize);
        if(bufferList == NULL) {
            NSLog(@"Unable to malloc memory");
            return;
        }
        status = AudioObjectGetPropertyData(deviceId, &propertyAddress, 0, NULL, &dataSize, bufferList);
        // If no buffers, device is not of this scope so free the list and try again
        if(status != kAudioHardwareNoError || bufferList->mNumberBuffers == 0) {
            if(status != kAudioHardwareNoError)
                NSLog(@"AudioObjectGetPropertyData (kAudioDevicePropertyStreamConfiguration) failed");
            free(bufferList);
            bufferList = NULL;
            return;
        }
    
        free(bufferList);
        bufferList = NULL;
    
        [devices addObject: @{ @"description":deviceName, @"uid":deviceUID, @"id":[NSNumber numberWithInt:deviceId] }];
    }];

    return [NSArray arrayWithArray:devices];
}

- (void)setDefaultInputDevice:(id)SetDefaultInputDevice {
    _defaultOutputDevice = SetDefaultInputDevice;
}

@end

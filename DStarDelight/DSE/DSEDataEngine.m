//
//  DSEDataEngine.m
//

#import "DStarEngine.h"

#import "DSEDataEngine.h"
#import "DSELinkDriverProtocol.h"
#import "DStarUtils.h"
#import "DSAudioHandler.h"
#import "DSEDV3KNetworkVocoder.h"

static NSMutableArray *vocoderDrivers = nil;
static NSMutableArray <Class> *linkDriverClasses = nil;

@interface DSEDataEngine ()

@property (nonatomic, readwrite) NSObject <DSELinkDriverProtocol> *network;
@property (nonatomic, readwrite) DSAudioHandler *audio;
@property (nonatomic, copy) NSString *sleepDestination;
@property (nonatomic, readonly) NSArray <id <DSELinkDriverProtocol>> *linkDrivers;
@property (nonatomic, readonly) dispatch_queue_t linkQueue;
@end

@implementation DSEDataEngine

+ (DSEDataEngine *) sharedInstance {
    static DSEDataEngine *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

-(id) init {
    self = [super init];
    if(self) {
        self.audio = [[DSVars shared] audioHandler];
        _network = nil;
        id vocoderDriverString = [[NSUserDefaults standardUserDefaults] stringForKey:@"VocoderDriver"];
        Class vocoderDriver = NSClassFromString(vocoderDriverString);
        if (vocoderDriver == nil) {
            vocoderDriver = NSClassFromString(DEFAULT_VOCODER);
        }
        self.vocoder = [[vocoderDriver alloc] init];
        
        _vocoder.audio = self.audio;
        
        _slowData = [[DSESlowDataCoder alloc] init];
        _slowData.delegate = self;
        
        //  Instantiate all the link drivers
        _linkQueue = dispatch_queue_create("net.polymicro.DStardelight.LinkOp", DISPATCH_QUEUE_SERIAL);
        NSMutableArray <id <DSELinkDriverProtocol>> *newLinkDrivers = [[NSMutableArray alloc] init];
        for(Class driver in linkDriverClasses) {
            NSObject <DSELinkDriverProtocol> *newDriver = [[driver alloc] init];
            [newLinkDrivers addObject:newDriver];
            newDriver.linkQueue = self.linkQueue;
            newDriver.delegate = self;
            [newDriver bind:@"myCall" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.myCall" options:nil];
            [newDriver bind:@"myCall2" toObject:[NSUserDefaultsController sharedUserDefaultsController] withKeyPath:@"values.myCall2" options:nil];
        }
        _linkDrivers = [NSArray arrayWithArray:newLinkDrivers];
        
        DSEDataEngine __weak *weakSelf = self;
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceWillSleepNotification object:NULL queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
            [weakSelf.audio stop];
            [weakSelf.vocoder stop];
            weakSelf.sleepDestination = weakSelf.network.linkTarget;
            [weakSelf.network unlink];
        }];
        
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceDidWakeNotification object:NULL queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
            [weakSelf.audio start];
            [weakSelf.vocoder start];
            [weakSelf linkTo:self.sleepDestination];
        }];        
    }
    
    return self;
}

-(void) dealloc {
}

- (void) setVocoder:(id<DSEVocoderDriver>)vocoder {
    _vocoder = vocoder;
    
    self.network.vocoder = vocoder;
    self.audio.vocoder = vocoder;
    self.vocoder.audio = self.audio;
    self.vocoder.network = self.network;
}

+(void)registerVocoderDriver:(Class)driver {
    if(!vocoderDrivers)
        vocoderDrivers = [[NSMutableArray alloc] init];
    
    [vocoderDrivers addObject:driver];
}

+(void)registerLinkDriver:(Class)driver {
    if(!linkDriverClasses)
        linkDriverClasses = [[NSMutableArray alloc] init];
    
    [linkDriverClasses addObject:driver];
}

+(NSArray *)vocoderDrivers {
    return [NSArray arrayWithArray:vocoderDrivers];
}

-(NSArray<NSString *> *)linkDriverDestinations {
    NSMutableArray *destinations = [[NSMutableArray alloc] init];
    
    for(id <DSELinkDriverProtocol> driver in self.linkDrivers) {
        [destinations addObjectsFromArray:driver.destinations];
    }
    return destinations;
}

-(BOOL)isDestinationValid:(NSString *)destination {
    NSUInteger linkIndex = [self.linkDrivers indexOfObjectPassingTest:^BOOL(id <DSELinkDriverProtocol> obj, NSUInteger idx, BOOL *stop) {
        BOOL test = [obj canHandleLinkTo:destination];
        if(test)
            *stop = YES;
        
        return test;
    }];
    
    return(linkIndex != NSNotFound);
}

-(void)linkTo:(NSString *)reflector {
    if(!reflector)
        return;
    
    if([self.network.linkTarget isEqualToString:reflector])
        return;
    
    [self unlink];
    
    for(NSObject <DSELinkDriverProtocol> *driver in self.linkDrivers) {
        if([driver canHandleLinkTo:reflector]) {
            self.network = driver;
            [driver linkTo:reflector];
            self.network.vocoder = self.vocoder;
            self.vocoder.network = self.network;
            break;
        }
    }
    
    if(self.network == nil) {
        NSError *error = [NSError errorWithDomain:@"DSEErrorDomain" code:2 userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%@ does not exist.", reflector]}];
        [self.delegate destinationDidError:reflector error:error];
        NSLog(@"Sending link failed notification");
    }
}

-(void)unlink {
        if(self.network) {
            [self.network unlink];
            self.network = nil;
            self.vocoder.network = nil;
        }
}

-(void)streamDidStart:(NSDictionary *)header {
    self.audio.receiving = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate streamDidStart:header];
    });
}

-(void)streamDidEnd:(NSNumber *)streamId atTime:(NSDate *)time {
    self.audio.receiving = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate streamDidEnd:streamId atTime:time];
    });
}

-(void)slowDataReceived:(NSString *)slowData forStreamId:(NSNumber *)streamId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate slowDataReceived:slowData forStreamId:streamId];
    });
}

-(void)locationReceived:(CLLocation *)location forStreamId:(NSNumber *)streamId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate locationReceived:location forStreamId:streamId];
    });
}

-(void)addData:(void *)data streamId:(NSUInteger)streamId {
    [self.slowData addData:data streamId:streamId];
}

-(void)getBytes:(void *)bytes forSequence:(NSUInteger)sequence {
    return [self.slowData getBytes:bytes forSequence:sequence];
}

-(void)destinationDidLink:(NSString *)destination {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate destinationDidLink:destination];
    });
}

-(void)destinationDidUnlink:(NSString *)destination {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate destinationDidUnlink:destination];
    });
}

-(void)destinationDidConnect:(NSString *)destination {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate destinationDidConnect:destination];
    });
}

-(void)destinationWillLink:(NSString *)destination {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate destinationWillLink:destination];
    });
}

-(void)destinationDidError:(NSString *)destination error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate destinationDidError:destination error:error];
    });
}

@end



#import "DSDV3KNetworkVocoder.h"

#import "DSDV3KVocoderSubclass.h"
#import <DStarEngine/DSEDataEngine.h>
#import "DSNetworkVocoderViewController.h"

#import <arpa/inet.h>
#import <sys/ioctl.h>

@interface DSEDV3KNetworkVocoder () {
    DSENetworkVocoderViewController *_configurationViewController;
}

@end

@implementation DSEDV3KNetworkVocoder

+(void) load {
    [DSEDataEngine registerVocoderDriver:self];
}

- (id) init {
    self = [super init];
    if(self) {
        _address = @"";
        _port = 2460;
        
        DSEDV3KNetworkVocoder __weak *weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock: ^(NSNotification *notification) {
                                                          NSLog(@"User defaults changing");
                                                          weakSelf.port = (short) [[NSUserDefaults standardUserDefaults] integerForKey:@"DV3KNetworkVocoderPort"];
                                                          NSString *address =[[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderAddress"];
                                                          if(address)
                                                              weakSelf.address = address;
                                                      }];

    }
    return self;
}

+(NSString *) driverName {
    return @"Network DV3000";
}

- (void) setProductId:(NSString *)productId {
    super.productId = productId;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ((DSENetworkVocoderViewController *)self.configurationViewController).productId.stringValue = productId;
    });
}

- (void) setVersion:(NSString *)version {
    super.version = version;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ((DSENetworkVocoderViewController *)self.configurationViewController).version.stringValue = version;
    });
}

- (void) setPort:(short)port {
    if(_port == port) return;
    
    _port = port;
    
    if(self.started)
        [self stop];
    
    [self start];
}

- (void) setAddress:(NSString *)address {
    if([address isEqualToString:_address]) return;
    
    _address = address;
    
    if(self.started)
        [self stop];
    
    [self start];
}

-(NSViewController *)configurationViewController {
    if(!_configurationViewController) {
        _configurationViewController = [[DSENetworkVocoderViewController alloc] init];
        _configurationViewController.driver = self;
    }
    return _configurationViewController;
}


- (BOOL) openPort {
    NSHost *destination = [NSHost hostWithAddress:self.address];
    if(!destination.address) {
        destination = [NSHost hostWithName:self.address];
    }
    
    if(!destination.address || self.port == 0)
        return NO;
    
    self.descriptor = socket(PF_INET, SOCK_DGRAM, 0);
    if(self.descriptor == -1) {
        NSLog(@"Error opening socket: %s\n", strerror(errno));
        return NO;
    }
    
    int one = 1;
    if(setsockopt(self.descriptor, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one))) {
        NSLog(@"Couldn't set socket to SO_REUSEADDR: %s\n", strerror(errno));
        return NO;
    }
    
    struct timeval tv = {
        .tv_sec = 1,
        .tv_usec = 0
    };
    if(setsockopt(self.descriptor, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv))) {
        NSLog(@"Couldn't set socket timeout: %s", strerror(errno));
        return NO;
    }
        
    struct sockaddr_in address = {
        .sin_len = sizeof(struct sockaddr_in),
        .sin_family = AF_INET,
        .sin_port = htons(self.port),
        .sin_addr.s_addr = inet_addr([destination.address cStringUsingEncoding:NSUTF8StringEncoding])
    };
    
    if(connect(self.descriptor, (const struct sockaddr *) &address, (socklen_t) sizeof(address))) {
        NSLog(@"Couldn't connect socket: %s\n", strerror(errno));
        return NO;
    }
    
    return YES;
}

- (BOOL) setNonblocking {
    if(fcntl(self.descriptor, F_SETFL, O_NONBLOCK) == -1) {
        NSLog(@"Couldn't set socket to nonblocking: %s\n", strerror(errno));
        return NO;
    }
    return YES;
}

- (void) closePort {
    if(self.descriptor) {
        close(self.descriptor);
        self.descriptor = 0;
    }
}

- (BOOL) readPacket:(struct dv3k_packet *)packet {
    ssize_t bytesRead;
    
    bytesRead = recv(self.descriptor, packet, sizeof(struct dv3k_packet), 0);
    if(bytesRead == -1) {
        NSLog(@"Couldn't read from DV3K: %s", strerror(errno));
        return NO;
    }
    
    if(packet->start_byte != DV3K_START_BYTE) {
        NSLog(@"No start byte in packet");
        return NO;
    }

    return YES;
}

- (BOOL) writePacket:(const struct dv3k_packet *)packet {
    ssize_t bytesWritten;
    
    bytesWritten = send(self.descriptor, packet, dv3k_packet_size(*packet), 0);
    if(bytesWritten == -1) {
        NSLog(@"Couldn't write packet to DV3K: %s", strerror(errno));
        return NO;
    }
    
    return YES;
}


@end

//
//  DNSHost.m
//
//  Created by Dave Carlton on 6/28/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import "DNSHost.h"

@implementation DNSHost

@synthesize name;
@synthesize names;    // unordered list
@synthesize address;    // arbitrary choice
@synthesize addresses;    // unordered list of IPv6 and IPv4 addresses
@synthesize localizedName;

+ (instancetype)currentHost {
    DNSHost *me = [[DNSHost alloc] init];
    me.address = [me getLocalIPAddress];
    me.names = [me hostnamesForAddress: me.address];
    me.name = me.names[0];
    me.addresses = [me addressesForHostname:me.name];
    return me;
}

+ (instancetype)hostWithName:(NSString *)name {
    DNSHost *me = [[DNSHost alloc] init];
    me.addresses = [me addressesForHostname: name];
    me.address = me.addresses[0];
    me.names = [me hostnamesForAddress: me.address];
    me.name = me.names[0];
    return me;
}

+ (instancetype)hostWithAddress:(NSString *)address {
    DNSHost *me = [[DNSHost alloc] init];
    me.names = [me hostnamesForAddress: address];
    me.name = me.names[0];
    me.addresses = [me addressesForHostname: me.name];
    me.address = me.addresses[0];
    return me;
}

- (BOOL)isEqualToHost:(DNSHost *)aHost {
    Boolean found = false;
    NSArray * taddrs = aHost.addresses;
    NSArray * saddrs = self.addresses;
    for (NSString *taddr in taddrs) {
        for (NSString *saddr in saddrs) {
            if (saddr == taddr) {
                found = true;
                break;
            }
        }
        if (found) {
            break;
        }
    }
    return found;
}

// Get the hostname for the given address.
- (NSArray *)hostnamesForAddress:(NSString *)address {
    struct addrinfo      hints;
    memset(&hints, 0, sizeof(hints));
//    hints.ai_flags    = AI_NUMERICHOST;
//    hints.ai_family   = PF_UNSPEC;
//    hints.ai_socktype = SOCK_STREAM;
//    hints.ai_protocol = 0;
    
    // TODO: Maybe should first get all addresses if they are not yet in and loop thru them
    struct sockaddr_in sa;
    sa.sin_family = AF_INET;
    char node[NI_MAXHOST];
    char hbuf[NI_MAXHOST];
    [address getCString:hbuf maxLength:NI_MAXHOST encoding:NSUTF8StringEncoding];
//    [@"76.173.89.2" getCString:hbuf maxLength:NI_MAXHOST encoding:NSUTF8StringEncoding];
    inet_pton(AF_INET, hbuf, &sa.sin_addr);
    int res = getnameinfo((struct sockaddr*)&sa, sizeof(sa), node, sizeof(node), NULL, 0, 0);
    NSMutableArray *hostnames = [NSMutableArray array];
    if (res == 0) {
        [hostnames addObject: [NSString stringWithCString: node encoding: NSUTF8StringEncoding]];
    }
    return hostnames;
}

// Get the host addresses for the given hostname.
- (NSArray *)addressesForHostname:(NSString *)hostname {
    struct addrinfo      hints, *res, *res0;
    memset(&hints, 0, sizeof(hints));
//    hints.ai_flags    = AI_ALL;
//    hints.ai_family   = PF_UNSPEC;
//    hints.ai_socktype = SOCK_STREAM;
//    hints.ai_protocol = 0;
    
    char hbuf[NI_MAXHOST];
    [hostname getCString:hbuf maxLength:NI_MAXHOST encoding:NSUTF8StringEncoding];
    int err= getaddrinfo([hostname UTF8String], [@"80" UTF8String], &hints, &res0);
    if (err) {
        NSLog(@"%s", gai_strerror(err));
    }
    int s = -1;
    char *cause = NULL;
    NSMutableArray *addresses = [NSMutableArray array];
   for (res = res0; res; res = res->ai_next) {
        s = socket(res->ai_family, res->ai_socktype,
                   res->ai_protocol);
        if (s < 0) {
            cause = "socket";
            continue;
        }
        
        if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {
            cause = "connect";
            close(s);
            s = -1;
            continue;
        }
       inet_ntop(AF_INET, res->ai_addr, hbuf, INET_ADDRSTRLEN);
       
       [addresses addObject: @"164.52.158.226"];
//       [addresses addObject: [NSString stringWithCString: hbuf encoding: NSUTF8StringEncoding]];
       NSLog(@"host: %s", hbuf);
    }
    if (s < 0) {
        NSLog(@"cause: %s", cause);
        /*NOTREACHED*/
    }
    freeaddrinfo(res0);
    return addresses;
}

- (NSString *)getLocalIPAddress {
    
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (NSError *)convertCFStreamErrorIntoNSError:(CFStreamError) streamError {
    NSError *err = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:streamError.error userInfo:NULL];
    return err;
}

@end


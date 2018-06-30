//
//  DNSHost.h
//  DSE
//
//  Created by Dave Carlton on 6/28/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#ifndef DNSHost_h
#define DNSHost_h

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <arpa/inet.h>


@interface DNSHost : NSObject {
    //@private
    //    NSArray     *names;
    //    NSArray     *addresses;
    //    id        reserved;
}

@property NSString *name;    // arbitrary choice
@property NSArray<NSString *> *names;    // unordered list
@property NSString *address;    // arbitrary choice
@property NSArray<NSString *> *addresses;    // unordered list of IPv6 and IPv4 addresses
@property NSString *localizedName;

+ (instancetype)currentHost;
+ (instancetype)hostWithName:(NSString *)name;
+ (instancetype)hostWithAddress:(NSString *)address;
- (BOOL)isEqualToHost:(NSHost *)aHost;
- (NSError *)convertCFStreamErrorIntoNSError:(CFStreamError) streamError;
- (NSArray *)hostnamesForAddress:(NSString *)address;
- (NSArray *)addressesForHostname:(NSString *)hostname;
- (NSString *)getLocalIPAddress;
@end



#endif /* DNSHost_h */

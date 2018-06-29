//
//  DNS.m
//  BTR
//
//  Created by Dave Carlton on 6/28/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <arpa/inet.h>


@interface DNS : NSObject
@private
NSArray     *names;
NSArray     *addresses;
id        reserved;
}

@property (nullable, readonly, copy) NSString *name;    // arbitrary choice
@property (readonly, copy) NSArray<NSString *> *names;    // unordered list

@property (nullable, readonly, copy) NSString *address;    // arbitrary choice
@property (readonly, copy) NSArray<NSString *> *addresses;    // unordered list of IPv6 and IPv4 addresses

@property (nullable, readonly, copy) NSString *localizedName API_AVAILABLE(macos(10.6)) API_UNAVAILABLE(ios, watchos, tvos);

+ (instancetype)currentHost;
+ (instancetype)hostWithName:(nullable NSString *)name;
+ (instancetype)hostWithAddress:(NSString *)address;
- (BOOL)isEqualToHost:(NSHost *)aHost;
- (NSError *)convertCFStreamErrorIntoNSError:(CFStreamError) streamError;
+ (NSArray *)hostnamesForAddress:(NSString *)address;
@end

@implementation DNSHost

+ (instancetype)currentHost {
}

+ (instancetype)hostWithName:(nullable NSString *)name {
}

+ (instancetype)hostWithAddress:(NSString *)address {

}

- (BOOL)isEqualToHost:(DNSHost *)aHost {
}

+ (NSError *)convertCFStreamErrorIntoNSError:(CFStreamError) streamError {
    NSError *err = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:streamError.error userInfo:NULL];
    return err;
}

+ (NSArray *)hostnamesForAddress:(NSString *)address {
    // Get the host reference for the given address.
    CFStreamError streamError;
    struct addrinfo      hints;
    struct addrinfo      *result = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags    = AI_NUMERICHOST;
    hints.ai_family   = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
    int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
    if (errorStatus != 0) return nil;
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) return nil;
    freeaddrinfo(result);
    CFHostRef hostRef = CFHostCreateWithAddress(kCFAllocatorDefault, addressRef);
    if (hostRef == nil) return nil;
    CFRelease(addressRef);
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostNames, &streamError);
    // always false
    if (!isSuccess){
        NSLog(@"error:%@",[self convertCFStreamErrorIntoNSError:streamError]);
        // error:Error Domain=kCFErrorDomainCFNetwork Code=2 "The operation couldn’t be completed. (kCFErrorDomainCFNetwork error 2.)" UserInfo=0x1cd29190 {kCFGetAddrInfoFailureKey=8}
        return nil;
    }

    // Get the hostnames for the host reference.
    CFArrayRef hostnamesRef = CFHostGetNames(hostRef, NULL);
    NSMutableArray *hostnames = [NSMutableArray array];
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)hostnamesRef count]; currentIndex++) {
        [hostnames addObject:[(__bridge NSArray *)hostnamesRef objectAtIndex:currentIndex]];
    }
    return hostnames;
}

+ (NSArray *)addressesForHostname:(NSString *)hostname {
    // Get the host reference for the given address.
    CFStreamError streamError;
    struct addrinfo      hints;
    struct addrinfo      *result = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_flags    = AI_NUMERICHOST;
    hints.ai_family   = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = 0;
//    int errorStatus = getaddrinfo([address cStringUsingEncoding:NSASCIIStringEncoding], NULL, &hints, &result);
//    if (errorStatus != 0) return nil;
    CFDataRef addressRef = CFDataCreate(NULL, (UInt8 *)result->ai_addr, result->ai_addrlen);
    if (addressRef == nil) return nil;
    freeaddrinfo(result);
    CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef _Nonnull)(hostname));
    if (hostRef == nil) return nil;
    CFRelease(addressRef);
    BOOL isSuccess = CFHostStartInfoResolution(hostRef, kCFHostAddresses, &streamError);
    // always false
    if (!isSuccess){
        NSLog(@"error:%@",[self convertCFStreamErrorIntoNSError:streamError]);
        // error:Error Domain=kCFErrorDomainCFNetwork Code=2 "The operation couldn’t be completed. (kCFErrorDomainCFNetwork error 2.)" UserInfo=0x1cd29190 {kCFGetAddrInfoFailureKey=8}
        return nil;
    }
    
    // Get the hostnames for the host reference.
    CFArrayRef addressesRef = CFHostGetAddressing(hostRef, NULL);
    NSMutableArray *addresses = [NSMutableArray array];
    for (int currentIndex = 0; currentIndex < [(__bridge NSArray *)addressesRef count]; currentIndex++) {
        [addresses addObject:[(__bridge NSArray *)addressesRef objectAtIndex:currentIndex]];
    }
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

+ (NSString *)hostWithName:[BTRDCSLink reflectorList][reflector]].address;

[NSHost hostWithAddress:self.address];
@end


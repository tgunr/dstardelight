//
// Created by Dave Carlton on 7/13/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

#import "DSReflectorSource.h"

@implementation DSReflectorSource

- (void)initWithName: (NSString *)name {
    _url = [NSURL URLWithString:name];

    if (![[_url scheme] length])
        _url = [NSURL URLWithString:[@"http://" stringByAppendingString: name]];
    self.name = name;
    self.active = [self isActive];
}


- (BOOL)isActive {
    NSError *error;
    NSHTTPURLResponse *response;
    NSMutableURLRequest *headRequest = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30.0f];
    [headRequest setHTTPMethod:@"HEAD"];
    if ([NSURLConnection canHandleRequest:headRequest]) {
        [NSURLConnection sendSynchronousRequest:headRequest returningResponse:&response error:&error];
    }
    _lastResponse = error;
//    NSURLSession *session = [NSURLSession sharedSession];
//    [[session dataTaskWithURL:[NSURL URLWithString:[_url absoluteString]]
//            completionHandler:^(NSData *data,
//                                NSURLResponse *response,
//                                NSError *error) {
//                // handle response
//                self.lastResponse = error;
//
//                if (error)
//                {
//
//                    NSLog(@"Connection failed! Error - %@ %@\n\n",
//                          [error localizedDescription],
//                          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
//
//                }
//                else
//                {
//
//                    NSLog(@"Finished Request \n\n");
//
//                }
//            }] resume];
//    return false;
        return [response statusCode] == 200;
}

@end

//
//  DSReflectors.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/13/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import "DSReflectors.h"

@implementation DSReflectors

- (void)updateReflectors {
    NSDate *reflectorsUpdated = [[NSUserDefaults standardUserDefaults] objectForKey: @"reflectorsUpdated"];
    NSDate *today = [NSDate date];
    NSTimeInterval since = [reflectorsUpdated timeIntervalSinceNow];
    // more than 24 hours?
    if (since > (24 * 60 * 60)) {
        // update reflector lists
        NSURL *url = [NSURL URLWithString:@"https://ar-dns.net/gateways"];
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSError *error;
            NSStringEncoding encoded;
            NSString *t1 = [NSString stringWithContentsOfURL:url usedEncoding:&encoded error:&error];
        });
    }
}


@end

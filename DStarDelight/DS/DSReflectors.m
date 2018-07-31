//
//  DSReflectors.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/13/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <AutoCoding/AutoCoding.h>
#import "DSReflectorSource.h"
#import "DSReflectors.h"

@implementation DSReflectors

const NSString *SOURCE_HEADER = @"# Prepared at ar-dns.net - ";
const NSString *HAMSTER_APPSUPPORT = @"Hamster";
const NSString *HAMSTER_REFLECTORS = @"Hamster/Reflectors.plist";

- (DSReflectors *)savedReflectors {
    _reflectorSources = [NSMutableArray arrayWithCapacity:5];
    _reflectorGateways = [NSMutableArray arrayWithCapacity:0];

    NSURL *reflectorsURL = [self reflectorsURL];
    // See if we have a saved list
    DSReflectors *reflectorList = [DSReflectors objectWithContentsOfFile:[reflectorsURL path]];

    if (reflectorList == nil | reflectorList.reflectorGateways == nil | reflectorList.reflectorGateways.count == 0) { // no list, so create one and save it
        // Do this async as it takes a few seconds to gather the data
        [self loadReflectors:reflectorsURL];
    } else {
        [reflectorList checkForOutDated];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reflectorsAreReady" object:reflectorList];
    }
    return self;
}

- (NSURL *)reflectorsURL {
    NSError *error = nil;

    NSFileManager *fileManager = [[NSFileManager alloc] init];
    // Saved appReflectors are in the Application Support folder
    NSURL *dir = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (error) {
        NSLog(@"Error finding app support directory %@", error);
    }
    // folder = reference to Application Support
    NSURL *folder = [[NSURL alloc] initFileURLWithPath:[dir path] isDirectory:YES];
    NSURL *appSupportFolderURL = [NSURL URLWithString:HAMSTER_APPSUPPORT relativeToURL:folder];
    NSURL *hamsterReflectorsURL = [NSURL URLWithString:(NSString *) HAMSTER_REFLECTORS relativeToURL:folder];
    BOOL result = [[NSFileManager defaultManager] createDirectoryAtURL:appSupportFolderURL withIntermediateDirectories:NO attributes:nil error:&error];

    if (result != 0) {
        NSLog(@"Could not create Application Support folder for Hamster");
    }

    return hamsterReflectorsURL;
}

// checkOutOfDate looks for the default list of sources in the preferences
// then pings them to see if alive. If alive, the source is added to the list for sources.
- (void)asyncLoadReflectors:(NSURL *)url usingBlock:(void (^)(void))block {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"DSReflectors: loadReflectors");
        NSArray *reflectorSourceDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"reflectorSources"];
        for (NSString *theSource in reflectorSourceDefaults) {
            DSReflectorSource *reflectorSource = [DSReflectorSource new];
            [reflectorSource initWithName:theSource];
            if (reflectorSource.active) {
                [self.reflectorSources addObject:reflectorSource];
            }
        }
        block();
    });

}

- (void)loadReflectors:(NSURL *)url {
    [self asyncLoadReflectors:url usingBlock:^{
        [self checkForOutDated];
        [self writeToFile:[url path] atomically:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reflectorsAreReady" object:self];
    }];
}

- (void)reloadReflectors {
    NSURL *reflectorsURL = [self reflectorsURL];
    [self asyncLoadReflectors:reflectorsURL usingBlock:^{
        [self updateReflectors];
        NSURL *reflectorsURL = [self reflectorsURL];
        [self writeToFile:[reflectorsURL path] atomically:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reflectorsAreReady" object:self];
    }];
}

- (void)checkForOutDated {
    NSLog(@"DSReflectors: checkForOutDated");
    NSDate *reflectorsUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"reflectorsUpdated"];

    NSTimeInterval since = fabs([reflectorsUpdated timeIntervalSinceNow]);
    NSUInteger numGateways = self.reflectorGateways.count;
    // TODO: Check monthly while debugging
    if (since > (30 * 24 * 60 * 60) | numGateways == 0) {
            [self updateReflectors];
    }
}

- (void)updateReflectors {
    NSLog(@"DSReflectors: updateReflectors");
    // update reflector lists
    for (DSReflectorSource *source in _reflectorSources) {
        NSURL *aSourceURL = source.url;
        NSError *error;
        NSStringEncoding encoded;
        NSCharacterSet *lineSet = [NSCharacterSet newlineCharacterSet];
        NSString *sourceContent = [NSString stringWithContentsOfURL:aSourceURL usedEncoding:&encoded error:&error];
        NSArray *contentLines = [sourceContent componentsSeparatedByCharactersInSet:lineSet];
        NSString *first = [contentLines firstObject];
        if ([first hasPrefix:(NSString *) SOURCE_HEADER]) {
            NSUInteger headerLength = [SOURCE_HEADER length];
            NSString *headerDateString = [first substringFromIndex:headerLength];
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
            // TODO: Fix this date problem
            dateFormatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz";
            NSDate *date = [dateFormatter dateFromString:headerDateString];
            NSLog(@"Date: %@", date);
            source.lastUpdate = date;
            lineSet = [NSCharacterSet whitespaceCharacterSet];
            NSMutableDictionary *reflectorList = [NSMutableDictionary dictionaryWithCapacity:0];
            for (NSString *aLine in contentLines) {
                NSArray *lineItems = [aLine componentsSeparatedByCharactersInSet:lineSet];
                if (lineItems.count == 2) {
                    DSReflector *aReflector = [DSReflector new];
                    aReflector.name = lineItems[0];
                    aReflector.ip = lineItems[1];
                    if (reflectorList[aReflector.name] == nil) {
                        reflectorList[aReflector.name] = aReflector;
                        [_reflectorGateways addObject:aReflector];
                    } else {
                        NSLog(@"Duplicate reflector: %@", aReflector.name);
                    }
                }
                // TODO: Debug code
                if ([reflectorList count] > 2)
                    break;
            }
        }
    }
    NSDate *today = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:today forKey:@"reflectorsUpdated"];
    
}

@end


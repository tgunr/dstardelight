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

const NSString *masterGatewaysListURL = @"https://ar-dns.net/gateways";
const NSString *SOURCE_HEADER = @"# Prepared at ar-dns.net - ";
const NSString *kCurrentSettingsFilename = @"Hamster/Reflectors";

- (void)createDefaultFile:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self loadReflectors];
        [self writeToFile:[url absoluteString] atomically:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"reflectorsAreReady" object:self];
    });
}

- (DSReflectors *)init {
    self = [super init];
    if (self) {
        _reflectorSources = [NSMutableArray arrayWithCapacity:5];
        _reflectors = [NSMutableArray arrayWithCapacity:0];

        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSError *err = nil;

        NSURL *dir = [fileManager URLForDirectory:NSApplicationSupportDirectory
                                         inDomain:NSUserDomainMask
                                appropriateForURL:nil
                                           create:YES
                                            error:&err];
        if (err) {
            NSLog(@"error finding app support directory %@", err);
        }

        NSURL *folder = [[NSURL alloc] initFileURLWithPath:[dir path] isDirectory:YES];
        NSURL *currentSettingsURL = [NSURL URLWithString:(NSString *) kCurrentSettingsFilename relativeToURL:folder];

        if (![fileManager fileExistsAtPath:[currentSettingsURL absoluteString]])
            [self createDefaultFile:currentSettingsURL];
        NSString *savePath = [[currentSettingsURL baseURL] absoluteString];
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:savePath error:&err];
        NSLog(@"files %@", files);

    }
    return self;
}

- (void)loadReflectors {
    NSArray *reflectorSourceDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"reflectorSources"];
    for (NSString *theSource in reflectorSourceDefaults) {
        DSReflectorSource *reflectorSource = [DSReflectorSource new];
        [reflectorSource initWithName:theSource];
        if (reflectorSource.active) {
            [self.reflectorSources addObject:reflectorSource];
        }
    }
//    NSUInteger c = _reflectorSources.count;
    NSDate *reflectorsUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"reflectorsUpdated"];
    NSDate *today = [NSDate date];
    NSTimeInterval since = fabs([reflectorsUpdated timeIntervalSinceNow]);
    if (since < (24 * 60 * 60)) {
            [self updateReflectors];
            [[NSUserDefaults standardUserDefaults] setObject:today forKey:@"reflectorsUpdated"];
    }
}

- (void)updateReflectors {
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
                        [_reflectors addObject:aReflector];
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
}


@end


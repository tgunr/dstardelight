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

- (DSReflectors *)init {
    self = [super init];
    if (self) {
        _reflectorSources = [NSMutableArray arrayWithCapacity:5];
        _reflectors = [NSMutableArray arrayWithCapacity:0];

        NSError *error = nil;
        BOOL result = false;

        NSFileManager *fileManager = [[NSFileManager alloc] init];
        // Saved appReflectors are in the Application Support folder
        NSURL *dir = [fileManager URLForDirectory:NSApplicationSupportDirectory
                                         inDomain:NSUserDomainMask
                                appropriateForURL:nil
                                           create:YES
                                            error:&error];
        if (error) {
            NSLog(@"Error finding app support directory %@", error);
        }
        // folder = reference to Application Support
        NSURL *folder = [[NSURL alloc] initFileURLWithPath:[dir path] isDirectory:YES];
        NSURL *appSupportFolderURL = [NSURL URLWithString:HAMSTER_APPSUPPORT relativeToURL:folder];
        NSURL *hamsterReflectorsURL = [NSURL URLWithString:(NSString *) HAMSTER_REFLECTORS relativeToURL:folder];
        result = [[NSFileManager defaultManager] createDirectoryAtURL:appSupportFolderURL withIntermediateDirectories:NO attributes:nil error:&error];

        if (result != 0) {
            NSLog(@"Could not create Application Support folder for Hamster");
            return self;
        }
        // See if we have a saved list
        DSReflectors *savedReflectors = [DSReflectors objectWithContentsOfFile: [hamsterReflectorsURL path]];

        if (!savedReflectors) { // no list, so create one and save it
            // Do this async as it takes a few seconds to gather the data
            dispatch_async(dispatch_get_main_queue(), ^{
                [self loadReflectors];
                    [self writeToFile:[hamsterReflectorsURL path] atomically:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"reflectorsAreReady" object:self];
            });
        } else {
            [savedReflectors checkForOutDated];
            self = savedReflectors;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"reflectorsAreReady" object:savedReflectors];
        }
    }
    return self;
}

// checkOutOfDate looks for the default list of sources in the preferences
// then pings them to see if alive. If alive, the source is added to the list for sources.
- (void)loadReflectors {
    NSArray *reflectorSourceDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:@"reflectorSources"];
    for (NSString *theSource in reflectorSourceDefaults) {
        DSReflectorSource *reflectorSource = [DSReflectorSource new];
        [reflectorSource initWithName:theSource];
        if (reflectorSource.active) {
            [self.reflectorSources addObject:reflectorSource];
        }
    }
    [self checkForOutDated];
}

- (void)checkForOutDated {
    NSDate *reflectorsUpdated = [[NSUserDefaults standardUserDefaults] objectForKey:@"reflectorsUpdated"];
    NSDate *today = [NSDate date];
    NSTimeInterval since = fabs([reflectorsUpdated timeIntervalSinceNow]);
    if (since > (24 * 60 * 60)) {
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


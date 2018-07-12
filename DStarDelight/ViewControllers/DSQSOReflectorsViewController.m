//
//  ReflectorsViewController.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DSQSOReflectorsViewController.h"

@implementation DSQSOReflectorsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *ref1 = [NSURL URLWithString:@"https://ar-dns.net/gateways"];
        refSources = [NSArray arrayWithContentsOfURL:ref1];
    }
    return self;
}
// Data Source
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.reflectorsView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 1;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
}

@end


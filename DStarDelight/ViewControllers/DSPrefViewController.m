//
//  DSPrefViewController.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/5/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import "DSPrefViewController.h"

@interface DSPrefViewController ()

@end

@implementation DSPrefViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void) viewDidAppear: (id) sender {
    
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *) tabViewItem {
    [super tabView:tabView didSelectTabViewItem:tabViewItem];
    NSUInteger index = [tabView indexOfTabViewItem:tabViewItem];
    NSLog(@"didSelectTabViewItem Index %ld", (long)index);
}

- (void)serialSelected: (id)sender {
    
}

- (void)networkSelected: (id)sender {
    
}
@end

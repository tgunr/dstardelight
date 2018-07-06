//
//  DSPrefViewController.h
//  DStarDelight
//
//  Created by Dave Carlton on 7/5/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DSPrefViewController : NSTabViewController

@property (nonatomic) NSInteger selectedDevice;

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)serialSelected: (id)sender;
- (void)networkSelected: (id)sender;
@end

NS_ASSUME_NONNULL_END

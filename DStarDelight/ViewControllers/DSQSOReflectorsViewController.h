//
//  ReflectorsViewController.h
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <AppKit/AppKit.h>

@class WKWebView;

@interface DSQSOReflectorsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate> {
    NSArray *refSources;
    
}

@property (strong) IBOutlet NSView *reflectorsView;
@property (weak) IBOutlet NSTableView *reflectorsTableView;
@property (nonatomic, strong) IBOutlet NSArrayController *reflectorTableController;
@property (weak) IBOutlet WKWebView *webView;

//- (IBAction)doReflectorDoubleClick:(id)sender;
//- (IBAction)addReflector:(id)sender;

@end

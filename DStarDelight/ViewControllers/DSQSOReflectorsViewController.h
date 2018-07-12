//
//  ReflectorsViewController.h
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

@interface DSQSOReflectorsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate> {
    NSArray *refSources;
    
}

@property (strong) IBOutlet NSView *reflectorsView;
@property (weak) IBOutlet NSTableView *reflectorsTableView;

@end

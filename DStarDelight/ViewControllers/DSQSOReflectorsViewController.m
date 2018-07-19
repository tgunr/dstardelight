//
//  ReflectorsViewController.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Webkit/WebKit.h>

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
#pragma - mark Data Source
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.reflectorsView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return 1;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
}

- (void)viewDidLoad {
 
    [self.reflectorsTableView registerForDraggedTypes:@[ @"net.polymicro.Dummy.reflector" ]];
    self.reflectorsTableView.dataSource = self;
    
    [self.reflectorsTableView enumerateAvailableRowViewsUsingBlock:^void(NSTableRowView *rowView, NSInteger row) {
        NSTextField *reflectorsView = ((NSTableCellView *)[rowView viewAtColumn:0]).textField;
//        if([reflectorsView.objectValue isEqualToString:destination])
//            reflectorsView.textColor = [NSColor redColor];
    }];

}

#pragma mark - Reflector Drag and Drop support

- (id <NSPasteboardWriting>) tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    if(tableView != self.reflectorsTableView)
        return nil;
    
    NSDictionary *reflector = self.reflectorTableController.arrangedObjects[row];
    
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
    [item setPropertyList:reflector forType:@"net.polymicro.Dummy.reflector"];
    
    return item;
}

-(NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    if(tableView != self.reflectorsTableView)
        return NO;
    
    [tableView setDropRow:row dropOperation:NSTableViewDropAbove];
    return NSDragOperationMove;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSDictionary *reflector = [info.draggingPasteboard propertyListForType:@"net.polymicro.Dummy.reflector"];
    
    if(tableView != self.reflectorsTableView)
        return NO;
    
    NSInteger oldIndex = [self.reflectorTableController.arrangedObjects indexOfObject:reflector];
    
    [self.reflectorTableController removeObject:reflector];
    if(row < oldIndex)
        [self.reflectorTableController insertObject:reflector atArrangedObjectIndex:row];
    else
        [self.reflectorTableController insertObject:reflector atArrangedObjectIndex:row - 1];
    
    return YES;
}


@end


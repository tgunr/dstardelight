

#import "DSMapPopupController.h"

@interface DSEMapPopupController ()

@end

@implementation DSEMapPopupController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.suppressClose = NO;
    // Do view setup here.
}

- (void) viewWillAppear {
    NSLog(@"Got annotation %@", self.annotation);
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotation:self.annotation];
    MKCoordinateRegion region = {
        .center = self.annotation.coordinate,
        .span = {
            .latitudeDelta = 10.0,
            .longitudeDelta = 10.0
        }
    };
    self.mapView.region = region;
    [self.mapView selectAnnotation:self.annotation animated:YES];
}

-(BOOL)popoverShouldClose:(NSPopover *)popover {
    return !self.suppressClose;
}

@end

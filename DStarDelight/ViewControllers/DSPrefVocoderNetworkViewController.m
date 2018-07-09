

#import "DSPrefVocoderNetworkViewController.h"

#import "DSDV3KNetworkVocoder.h"

@interface DSPrefVocoderNetworkViewController ()

@end

@implementation DSPrefVocoderNetworkViewController

- (id) init {
//    self = [super initWithNibName:@"DSNetworkVocoderView" bundle:nil];
    _productId.stringValue = @"";
    _version.stringValue = @"";
    return self;
}

-(void)dealloc {
    NSLog(@"Deallocate");
}

//- (void)viewWillAppear {
//    CGFloat newHeight = 29;
//    NSArray *contents = self.view.subviews;
//    for (NSView *aView in contents) {
//        newHeight += aView.bounds.size.height;
//    }
//    CGFloat myWidth = self.view.bounds.size.width;
//    CGFloat myHeight = self.view.bounds.size.height;
//    NSSize oldSize = self.preferredContentSize;
//    NSSize size = NSMakeSize(myWidth, newHeight);
//    [self setPreferredContentSize:size];
//    NSRect newBounds = NSMakeRect(self.view.bounds.origin.x, self.view.bounds.origin.y, 497, 283);
//    self.view.bounds = newBounds;
//}

- (void) viewDidAppear {
    _vocoderAddress.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderAddress"];
    _vocoderPort.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderPort"];
    
    
    if (self.driver) {
        self.version.stringValue = self.driver.version;
        self.productId.stringValue = self.driver.productId;
    }
}

-(IBAction)doTest:(id)sender {
    [self.driver stop];
    [self.driver start];
}

@end

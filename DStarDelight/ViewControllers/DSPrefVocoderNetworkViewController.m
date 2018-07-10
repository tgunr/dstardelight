

#import "DSPrefVocoderNetworkViewController.h"

#import "DSDV3KNetworkVocoder.h"
#import "DStarUtils.h"

@interface DSPrefVocoderNetworkViewController ()

@end

@implementation DSPrefVocoderNetworkViewController

- (id) init {
    _productId.stringValue = @"";
    _version.stringValue = @"";
    DSVars.shared.DV3KProductID = _productId.stringValue;
    DSVars.shared.DV3KVersion = _version.stringValue;
    DSVars.shared.networkDriver = nil;
    return self;
}

-(void)dealloc {
    NSLog(@"Deallocate");
}

- (void)viewWillAppear {
    CGFloat newHeight = 29;
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
}

- (void)viewDidAppear{
    _vocoderAddress.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderAddress"];
    _vocoderPort.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderPort"];
    
    _driver = DSVars.shared.networkDriver;
    if (_driver) {
        self.version.stringValue = _driver.version;
        self.productId.stringValue = _driver.productId;
    }
}

-(IBAction)doTest:(id)sender {
    [_driver stop];
    [_driver start];
}

@end

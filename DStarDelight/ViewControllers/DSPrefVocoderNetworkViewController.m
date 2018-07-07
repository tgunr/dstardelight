

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

- (void) viewDidAppear {
    _vocoderAddress.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderAddress"];
    _vocoderPort.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderPort"];
    
    if (self.driver) {
        self.version.stringValue = self.driver.version;
        self.productId.stringValue = self.driver.productId;
    }
}

-(void)dealloc {
    NSLog(@"Deallocing");
}

-(IBAction)doTest:(id)sender {
    [self.driver stop];
    [self.driver start];
}

@end

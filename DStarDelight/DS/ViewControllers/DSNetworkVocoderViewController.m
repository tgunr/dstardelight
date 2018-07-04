

#import <DStarEngine/DSEDataEngine.h>
#import "DSNetworkVocoderViewController.h"

@interface DSNetworkVocoderViewController ()

@end

@implementation DSNetworkVocoderViewController

- (id) init {
    self = [super initWithNibName:@"DSENetworkVocoderView" bundle:nil];
    
//    [[DSVars shared] SetNetworkConfigurationViewController: self];

    return self;
}

- (void) viewDidAppear {
//    self.version.stringValue = self.driver.version;
//    self.productId.stringValue = self.driver.productId;
}

-(void)dealloc {
    NSLog(@"Deallocing");
}

-(IBAction)doTest:(id)sender {
//    [self.driver stop];
//    [self.driver start];
}

@end

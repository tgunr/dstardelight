

#import "DSNetworkVocoderViewController.h"

#import "DSDV3KNetworkVocoder.h"

@interface DSNetworkVocoderViewController ()

@end

@implementation DSNetworkVocoderViewController

- (id) init {
    self = [super initWithNibName:@"DSNetworkVocoderView" bundle:nil];

    return self;
}

- (void) viewDidAppear {
    self.version.stringValue = self.driver.version;
    self.productId.stringValue = self.driver.productId;
}

-(void)dealloc {
    NSLog(@"Deallocing");
}

-(IBAction)doTest:(id)sender {
    [self.driver stop];
    [self.driver start];
}

@end

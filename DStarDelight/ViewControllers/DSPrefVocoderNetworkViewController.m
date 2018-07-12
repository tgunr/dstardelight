

#import "DSPrefVocoderNetworkViewController.h"

#import "DSDV3KNetworkVocoder.h"
#import "DStarUtils.h"

@interface DSPrefVocoderNetworkViewController ()

@end

@implementation DSPrefVocoderNetworkViewController

- (id) init {
    self.productId.stringValue = @"";
    self.version.stringValue = @"";
    self.statusImageView.image = [NSImage imageNamed:@"Grey"];

    DSVars.shared.DV3KProductID = self.productId.stringValue;
    DSVars.shared.DV3KVersion = self.x`version.stringValue;
    DSVars.shared.networkDriver = nil;
    return self;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    NSArray *viewObjects;
    
    // Custom initialization.
    BOOL r = [[NSBundle mainBundle] loadNibNamed:@"DSPrefVocoderNetworkViewController" owner:self topLevelObjects:&viewObjects];
    if (r) {
        NSLog(@"DSPrefVocoderNetworkViewController loaded: %@", self);
    }
    
    return self;
}

- (void)clearConnection {
    self.productId.stringValue = @"";
    self.version.stringValue = @"";
    self.connectionStatus.stringValue = @"Disconnected";
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder: decoder];
    [self clearConnection];
    self.statusImageView.image = [NSImage imageNamed:@"Grey"];
    
    DSVars.shared.DV3KProductID = self.productId.stringValue;
    DSVars.shared.DV3KVersion = self.version.stringValue;
    self.driver = DSVars.shared.networkDriver;
    self.driver.delegate = self;
    return self;
}

-(void)dealloc {
    NSLog(@"Deallocate");
}

- (void)viewDidAppear{
    self.vocoderAddress.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderAddress"];
    self.vocoderPort.stringValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"DV3KNetworkVocoderPort"];
    
    self.driver = DSVars.shared.networkDriver;
    if (self.driver) {
        self.version.stringValue = self.driver.version;
        self.productId.stringValue = self.driver.productId;
        if ([[self.driver version] isEqualToString: @""]) {
            [self setStatus: stopped];
        } else {
            [self setStatus: started];
        }
    }
}

- (void)setStatus: (DriverStatus)status {
    switch(status) {
        case undefined:
            self.statusImageView.image = [NSImage imageNamed:@"Grey"];
            NSLog(@"Grey");
            break;
        case stopped:
            self.statusImageView.image = [NSImage imageNamed:@"Red"];
            [self clearConnection];
            NSLog(@"Red");
            break;
        case started:
            self.statusImageView.image = [NSImage imageNamed:@"Green"];
            self.connectionStatus.stringValue = @"Connected";
            NSLog(@"Green");
            break;
    }
}

-(IBAction)tryConnection:(id)sender {
    [self.driver stop];
    [self.driver start];
}

@end

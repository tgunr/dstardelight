

#import "DSSerialVocoderViewController.h"

@interface DSSerialVocoderViewController ()
@end

@implementation DSSerialVocoderViewController

- (id) init {
    self = [super initWithNibName:@"DSESerialVocoderView" bundle:nil];
    
    return self;
}

-(void)viewDidLoad {
    NSLog(@"View Loaded");
}

- (void)viewDidAppear {
    [super viewDidAppear];
    
    [self refreshDevices];
    self.version.stringValue = self.driver.version;
    self.productId.stringValue = self.driver.productId;

    [self.speedPopup selectItemWithTitle:[NSString stringWithFormat:@"%ld", self.driver.speed]];
    [self.serialPortPopup selectItemWithTitle:self.driver.serialPort];
}

-(void)refreshDevices {
    [self.serialPortPopup removeAllItems];
    [self.serialPortPopup addItemsWithTitles:[DSDV3KSerialVocoder ports]];
}

-(void)dealloc {
    NSLog(@"Deallocing");
}

-(IBAction)doChangeSerialPort:(id)sender {
    self.driver.serialPort = self.serialPortPopup.selectedItem.title;
    [[NSUserDefaults standardUserDefaults] setObject:self.driver.serialPort forKey:@"DV3KSerialVocoderPort"];
}

-(IBAction)doChangeSpeed:(id)sender {
    self.driver.speed = self.speedPopup.selectedItem.title.intValue;
    [[NSUserDefaults standardUserDefaults] setInteger:self.driver.speed forKey:@"DV3KSerialVocoderSpeed"];
}

@end

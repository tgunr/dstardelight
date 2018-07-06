

#import "DSPrefVocoderViewController.h"
#import "DSEVocoderDriver.h"
#import "DSEDataEngine.h"

@interface DSPrefVocoderViewController ()

@property (nonatomic) NSViewController *configurationViewController;

-(void)replaceConfigurationViewControllerWith:(NSViewController *)viewController;

@end

@implementation DSPrefVocoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.vocoderType removeAllItems];
    for(Class driver in [DSEDataEngine vocoderDrivers]) {
        [self.vocoderType addItemWithTitle:[driver driverName]];
        NSMenuItem *addedItem = [self.vocoderType itemWithTitle:[driver driverName]];
        addedItem.representedObject = driver;
        if([[[[DSEDataEngine sharedInstance].vocoder class] driverName] isEqualToString:[driver driverName]])
            [self.vocoderType selectItem:addedItem];
    }
    
    [self replaceConfigurationViewControllerWith:[[DSEDataEngine sharedInstance].vocoder configurationViewController]];
}

-(void)replaceConfigurationViewControllerWith:(NSViewController *)viewController {
    if(self.configurationViewController)
        [self removeChildViewControllerAtIndex:[self.childViewControllers indexOfObject:self.configurationViewController]];
    [self addChildViewController:viewController];
    self.configurationViewController = viewController;
    
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    viewController.view.identifier = @"Configuration";
    for(NSView *view in self.view.subviews)
        if([view.identifier isEqualToString:@"Configuration"])
            [self.view replaceSubview:view with:viewController.view];
    
    NSDictionary *viewsDictionary = @{ @"vocoderType" : self.vocoderType,
                                       @"configuration" : self.configurationViewController.view };
    
    NSMutableArray *constraints = [NSMutableArray arrayWithArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[vocoderType]-[configuration]|"
                                                                                                         options:0
                                                                                                         metrics:nil
                                                                                                           views:viewsDictionary]];
    [constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|[configuration]|"
                                                                             options:0
                                                                             metrics:nil
                                                                               views:viewsDictionary]];
    
    [self.view addConstraints:constraints];
    
    //[self.view updateConstraintsForSubtreeIfNeeded];
    //[self.view layoutSubtreeIfNeeded];
    
    /* NSLog(@"Containing View Constraints: %@", self.view.constraints);
    for(NSView *view in self.view.subviews) {
        NSLog(@"%@ Contraints: %@", view.identifier, view.constraints);
    } */
}

-(void)selectVocoder:(id)sender {
    Class driver = self.vocoderType.selectedItem.representedObject;
    id <DSEVocoderDriver> newVocoder = [[driver alloc] init];
    
    NSLog(@"doing select vocoder");
    
//    [self replaceConfigurationViewControllerWith:[newVocoder configurationViewController]];
    [self replaceCurrentVocoderWith:newVocoder];
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromClass(driver) forKey:@"VocoderDriver"];
 }

-(void) replaceCurrentVocoderWith:(id <DSEVocoderDriver>)vocoder {
    NSObject <DSEVocoderDriver> *oldVocoder = [DSEDataEngine sharedInstance].vocoder;
    
    [oldVocoder stop];
    [DSEDataEngine sharedInstance].vocoder = vocoder;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [vocoder start];
    });

    for(NSString *binding in [oldVocoder exposedBindings])
        [oldVocoder unbind:binding];
}

@end

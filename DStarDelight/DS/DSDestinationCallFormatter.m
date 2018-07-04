

#import "DSDestinationCallFormatter.h"

#import "DSEDataEngine.h"

@interface DSDestinationCallFormatter ()

@end

@implementation DSDestinationCallFormatter

- (BOOL) getObjectValue:(out __autoreleasing id *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing *)error {
    *obj = [string stringByReplacingOccurrencesOfString:@"•" withString:@" "];

    if(![[DSEDataEngine sharedInstance] isDestinationValid:*obj]) {
        if(error)
            *error = @"Link destination not found";
        return NO;
    }
        
    return YES;
}

@end

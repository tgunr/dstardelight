
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "DSESlowDataDelegate.h"


@interface DSESlowDataCoder : NSObject <CLLocationManagerDelegate>

-(void)addData:(void *)data streamId:(NSUInteger)streamId;
-(void)getBytes:(void *)bytes forSequence:(NSUInteger)sequence;

@property (nonatomic, copy) NSString *message;
@property (nonatomic, weak) NSObject <DSESlowDataDelegate> *delegate;

@end

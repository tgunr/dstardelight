

@class DSEAprsLocation;

@protocol DSESlowDataDelegate <NSObject>

-(void)slowDataReceived:(NSString *)slowData forStreamId:(NSNumber *)streamId;
-(void)locationReceived:(DSEAprsLocation *)location forStreamId:(NSNumber *)streamId;

@end

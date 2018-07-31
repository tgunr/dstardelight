//
//  DSEDataEngineDelegate.h
//

@import CoreLocation;

@protocol DSEDataEngineDelegate <NSObject>

-(void)streamDidStart:(NSMutableDictionary *)header;
-(void)streamDidEnd:(NSNumber *)streamId atTime:(NSDate *)date;
-(void)slowDataReceived:(NSString *)slowData forStreamId:(NSNumber *)streamId;
-(void)locationReceived:(CLLocation *)location forStreamId:(NSNumber *)streamId;
-(void)destinationDidLink:(NSString *)destination;
-(void)destinationDidUnlink:(NSString *)destination;
-(void)destinationDidError:(NSString *)destination error:(NSError *)error;
-(void)destinationWillLink:(NSString *)destination;
-(void)destinationDidConnect:(NSString *)destination;

@end

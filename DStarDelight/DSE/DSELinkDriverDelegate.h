

@protocol DSELinkDriverDelegate <NSObject>

-(void)addData:(void *)data streamId:(NSUInteger)streamId;
-(void)getBytes:(void *)bytes forSequence:(NSUInteger)sequence;

#pragma mark - Delegate methods
-(void)destinationWillLink:(NSString *)destination;
-(void)destinationDidLink:(NSString *)destination;
-(void)destinationDidUnlink:(NSString *)destination;
-(void)destinationDidConnect:(NSString *)destination;
-(void)streamDidStart:(NSDictionary *)header;
-(void)streamDidEnd:(NSNumber *)streamId atTime:(NSDate *)date;

-(void)destinationDidError:(NSString *)destination error:(NSError *)error;

@end

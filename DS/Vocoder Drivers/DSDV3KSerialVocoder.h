

#import <DStarEngine/DStarEngine.h>

@interface DSDV3KSerialVocoder : DSEDV3KVocoder

+ (NSArray *)ports;

@property (nonatomic, copy) NSString *serialPort;
@property (nonatomic) long speed;

@end

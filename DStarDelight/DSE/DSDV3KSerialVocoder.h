

#import "DSEDV3KVocoder.h"

@interface DSDV3KSerialVocoder : DSEDV3KVocoder

+ (NSArray *)ports;

@property (nonatomic, copy) NSString *serialPort;
@property (nonatomic) long speed;

@end

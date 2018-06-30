

#import "DSDV3KVocoderSubclass.h"

@interface DSEDV3KSerialVocoder : DSEDV3KVocoder

+ (NSArray *)ports;

@property (nonatomic, copy) NSString *serialPort;
@property (nonatomic) long speed;

@end

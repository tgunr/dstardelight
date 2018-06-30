

#import <DStarEngine/DSEDV3KVocoder.h>

#import "DSDV3KPacket.h"

@interface DSEDV3KVocoder ()

@property (nonatomic) BOOL started;
@property (nonatomic) int descriptor;
@property (nonatomic, readwrite, copy) NSString *productId;
@property (nonatomic, readwrite, copy) NSString *version;


- (BOOL) openPort;
- (BOOL) setNonblocking;
- (BOOL) readPacket:(struct dv3k_packet *)packet;
- (BOOL) writePacket:(const struct dv3k_packet *)packet;
- (void) closePort;

@end

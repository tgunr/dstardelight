

@import CoreLocation;
@import MapKit;

@interface DSEAprsLocation : NSObject <MKAnnotation>

@property (nonatomic) CLLocation *location;
@property (nonatomic, copy) NSString *callsign;
@property (nonatomic, getter=hasMessaging) BOOL *messaging;
@property (nonatomic) char symbol;
@property (nonatomic) char symbolTable;
@property (nonatomic, readonly) NSString *tnc2Packet;
@property (nonatomic, copy) NSString *comment;
@property (nonatomic, readonly) NSString *dprsPacket;

-(id)initWithNmeaSentence:(NSString *)nmeaSentence;
-(id)initWithAprsPacket:(NSString *)aprsString;

@end

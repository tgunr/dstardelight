

@import MapKit;

@interface DSEMapPopupController : NSViewController <NSPopoverDelegate>

@property (nonatomic) MKPointAnnotation *annotation;
@property (weak) IBOutlet MKMapView *mapView;
@property (nonatomic) NSNumber *qsoId;
@property (nonatomic) BOOL suppressClose;

@end

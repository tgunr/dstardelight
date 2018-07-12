
#import "DSEDV3KVocoder.h"

@class DSPrefVocoderNetworkViewController;

@interface DSEDV3KNetworkVocoder : DSEDV3KVocoder {
}

// XXX This should probably be NSHost!
@property (nonatomic, copy) NSString *address;
@property (nonatomic) short port;
@property id delegate;

@end

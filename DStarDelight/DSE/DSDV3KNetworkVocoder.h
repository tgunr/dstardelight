
#import "DSEDV3KVocoder.h"

@class DSPrefVocoderNetworkViewController;

@interface DSEDV3KNetworkVocoder : DSEDV3KVocoder {
        DSPrefVocoderNetworkViewController *_configurationViewController;
}

// XXX This should probably be NSHost!
@property (nonatomic, copy) NSString *address;
@property (nonatomic) short port;

@end

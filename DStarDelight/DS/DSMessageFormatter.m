

#import "DSMessageFormatter.h"

@interface DSMessageFormatter ()

@end

@implementation DSMessageFormatter

- (BOOL) isPartialStringValid:(NSString *__autoreleasing *)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString *__autoreleasing *)error {
    
    if(strlen((*partialStringPtr).UTF8String) > 20) {
        proposedSelRangePtr = &origSelRange;
        
        // XXX Make the static analyzer not complain
        (void)proposedSelRangePtr;
        return NO;
    }
    
    return YES;
}

- (NSString *) stringForObjectValue:(id)obj {
    return (NSString *) obj;
}

- (BOOL) getObjectValue:(out __autoreleasing id *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing *)error {
    *obj = string;
    return YES;
}


@end

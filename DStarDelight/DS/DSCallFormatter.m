

#import "DSCallFormatter.h"

@interface DSCallFormatter () {
    NSCharacterSet *invalidChars;
    NSRegularExpression *commandRegex;
}

@end

@implementation DSCallFormatter

- (id) init {
    self = [super init];
    if(self) {
        NSError *error = NULL;
        invalidChars = [NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz• "].invertedSet;
        commandRegex = [NSRegularExpression regularExpressionWithPattern:@"[ ]{7}[A-Z]{1}" options:NSRegularExpressionCaseInsensitive error:&error];\
        
        _maxLength = 8;
    }
    
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return [self init];
}

- (BOOL) isPartialStringValid:(NSString *__autoreleasing *)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString *__autoreleasing *)error {
    
    NSString *proposedString = *partialStringPtr;
    if(proposedString.length > _maxLength) {
        proposedSelRangePtr = &origSelRange;
        
        // XXX Make the static analyzer not complain
        (void)proposedSelRangePtr;
        return NO;
    }

    NSArray *components = [proposedString componentsSeparatedByCharactersInSet:invalidChars];
    if(components.count > 1) {
        *partialStringPtr = [NSString stringWithString:origString];
        proposedSelRangePtr->length = origSelRange.length;
        proposedSelRangePtr->location = origSelRange.location;
    } else {
        *partialStringPtr = [[proposedString uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"•"];
    }
    
    return NO;
}

- (NSString *) stringForObjectValue:(id)obj {
    NSString *inString = (NSString *) obj;
    NSString *newString;
    
    if(obj == nil)
        return nil;
    
    if([commandRegex numberOfMatchesInString:inString options:NSMatchingAnchored range:NSMakeRange(0, [inString length])] == 0) {
        newString = [inString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    } else {
        newString = inString;
    }
    
    return [newString stringByReplacingOccurrencesOfString:@" " withString:@"•"];
}

- (BOOL) getObjectValue:(out __autoreleasing id *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing *)error {
    *obj = [string stringByReplacingOccurrencesOfString:@"•" withString:@" "];
    return YES;
}

@end

//
//  objective_category_swizzle_object.m
//
//  Created by Dave Carlton on 6/30/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "objective_category_swizzle_object.h"

// FOR CATEGORIES (From same class into same class)
// `swizzle()` allows replacing methods in a Category while still leaving access
//  to the original akin to `super` for subclasses

// INJECT/REPLACE (loses original)
void (^inject)(Class, SEL, SEL) = ^(Class c, SEL orig, SEL new){
    Method newMethod = class_getInstanceMethod(c, new);
    class_replaceMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
};

// SWIZZLE (old method is available under new one's name)
void (^swizzle)(Class, SEL, SEL) = ^(Class c, SEL orig, SEL new){
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
};

// USAGE
// Note, call [self _my_prepareForSegue:sender] for original version
swizzle(self.class, @selector(prepareForSegue:sender:), @selector(_my_prepareForSegue:sender:));

// Pure override/replace
inject(self.class, @selector(delegate), @selector(_es_delegate));
inject(self.class, @selector(setDelegate:), @selector(_es_setDelegate:));
@implementation NSObject (objective_category_swizzle_object)

@end

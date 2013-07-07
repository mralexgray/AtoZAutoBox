//
//  NSObject+Primitives.m
//  AtoZAutoBox
//
//  Created by Alex Gray on 6/25/13.
//  Copyright (c) 2013 Alex Gray. All rights reserved.
//

#import "NSObject+Primitives.h"

@implementation NSObject (Primitives)

- (void *)performSelector:(SEL)selector withValue:(void *)value {
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
	[invocation setSelector:selector];
	[invocation setTarget:self];
	[invocation setArgument:value atIndex:2];
	[invocation invoke];
	NSUInteger length = [[invocation methodSignature] methodReturnLength];

	if (length > 0) {                       // If method is non-void:
		void *buffer = (void *)malloc(length);
		[invocation getReturnValue:buffer];
		return buffer;
	}
	return NULL;                            // If method is void:
}

@end


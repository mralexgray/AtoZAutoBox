
#import "NSObject+DynamicProperties.h"


//@implementation NSObject (mAVFK)
//-(NSMutableArray *) mAVFK { return  [self mutableArrayValueForKey:<#(NSString *)#>valueForKeyPath
//]
//@end


@interface HigherOrderMessage : NSProxy {	//Class isa;
	NSUInteger retainCount;
	NSMethodSignature *(^methodSignatureForSelector)(SEL selector);
	void (^forward)(NSInvocation*capture);
}
@end
@implementation HigherOrderMessage
+ (id)HOMWithGetSignatureForSelector:(NSMethodSignature *(^)(SEL selector))_sig
		 							  capture:(void (^)(NSInvocation *message))_forward	{
	HigherOrderMessage *message =  [HigherOrderMessage alloc];		// class_createInstance(self, 0);
	if (message) {		message -> methodSignatureForSelector 	= [_sig copy];
							message -> forward 							= [_forward copy];
							message -> retainCount 						= 1;
	}
	return message;
}
- (NSMethodSignature*) methodSignatureForSelector:(SEL)aSelector 						{	return methodSignatureForSelector(aSelector);	}
- (void) forwardInvocation:(NSInvocation*)invocation 										{	forward(invocation);	}

@end
@implementation NSObject (HigherOrderMessage)
+ (BOOL) testIfResponds {
	NSString *string = @"string";
	NSMutableArray *array = [NSMutableArray array];
	@try {
		NSLog(@"%@", [string stringByAppendingString:string]);   // stringstring
		NSLog(@"%@", [(NSString*)array stringByAppendingString:string]);  // -[__NSArrayM stringByAppendingString:]: unrecognized selector sent to instance
	} @catch (NSException * e) {
		NSLog(@"error: %@", e);
		NSLog(@"now with ifResponds...");
		NSLog(@"%@", [string.ifResponds stringByAppendingString:string]); // stringstring
		NSLog(@"%@", [array.ifResponds stringByAppendingString:string]); // (null)
		NSLog(@"%@", NSStringFromClass([array.ifResponds class]));  // HigherOrderMessage ( should maybe be nsarray, not sure )
	}
	return YES;
}
- (id) ifResponds 		{
	return [HigherOrderMessage HOMWithGetSignatureForSelector:^(SEL selector) {
		return [self methodSignatureForSelector:selector] ?: [NSMethodSignature signatureWithObjCTypes:"@@:"];
	} capture:^(NSInvocation *mess) { [mess invokeWithTarget:([self respondsToSelector:mess.selector] ? self : nil)]; }];
}
@end


@interface CPropertyFactory : NSObject
@end
@implementation CPropertyFactory

//+ (instancetype) newKinda:(Class)k {	id newK = k.new;  return (k*)newK;	}

- (BOOL)configure:(Class)inClass getter:(PGETTER)inGetter setter:(PSETTER)inSetter error:(NSError * *)outError {

	   unsigned int    thePropertyCount = 0;  NSUInteger thePropertyIndex;
	objc_property_t      *theProperties = class_copyPropertyList(inClass, &thePropertyCount);

	for (thePropertyIndex = 0; thePropertyIndex != thePropertyCount; ++thePropertyIndex)
		[self configure:inClass property:theProperties[thePropertyIndex] getter:inGetter setter:inSetter error:NULL];
	if (theProperties != NULL)	free(theProperties);	return YES;
}
- (BOOL)configure:(Class)inClass propertyName:(NSString *)inProperty getter:(PGETTER)inGetter setter:(PSETTER)inSetter error:(NSError * *)outError {

	objc_property_t theProperty = class_getProperty(inClass, [inProperty UTF8String]);
	return theProperty == NULL ? NO : [self configure:inClass property:theProperty getter:inGetter setter:inSetter error:outError];
}
- (BOOL)configure:(Class)inClass property:(objc_property_t)inProperty getter:(PGETTER)inGetter setter:(PSETTER)inSetter error:(NSError * *)outError {

	BOOL theResult,  theDynamicFlag,  theReadonlyFlag;
		  theResult = theDynamicFlag = theReadonlyFlag = NO;
	inGetter = [inGetter copy];
	inSetter = [inSetter copy];   //    BOOL theNonAtomicFlag = NO;
	const   char          *theType = NULL;
	unsigned int theAttributeCount = 0;

	objc_property_attribute_t *theAttributes = property_copyAttributeList(inProperty, &theAttributeCount);

	// See http://developer.apple.com/library/ios/#DOCUMENTATION/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html for all flags.
	for (unsigned int theAttributeIndex = 0; theAttributeIndex != theAttributeCount; ++theAttributeIndex) {
		if (strlen(theAttributes[theAttributeIndex].name) == 1) {
			switch (theAttributes[theAttributeIndex].name[0]) {
				case 'D': theDynamicFlag = YES;											break;
				case 'T': theType = theAttributes[theAttributeIndex].value;		break;
				case 'R': theReadonlyFlag = YES;											break;
				case 'N':																		break; 	// theNonAtomicFlag = YES;
			}
		}
	}

	if (theDynamicFlag == YES && theType != NULL) {	NSString *thePropertyName, *theGetterName, *theSetterName, *theGetterType, *theSetterType;

		thePropertyName 		= [NSString stringWithUTF8String:property_getName(inProperty)];
		theGetterName 			= thePropertyName;
		theSetterName 			= [NSString stringWithFormat:@"set%@%@:", [thePropertyName substringToIndex:1].uppercaseString, [thePropertyName substringFromIndex:1]];
		theGetterType 			= [NSString stringWithFormat:@"%s@:", 		theType];
		theSetterType 			= [NSString stringWithFormat:@"v@:%s", 	theType];
		__block id theGetterIMPBlock = NULL;
		__block id theSetterIMPBlock = NULL;
		// http://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
		if (theType[0] == '@') {
			theGetterIMPBlock = ^(id _self) { return(inGetter(_self, thePropertyName)); };
			theSetterIMPBlock = ^(id _self, NSString *value) { inSetter(_self, thePropertyName, value); };
		}
		else if (theType[0] != '{') {
			strcmp(theType, @encode(BOOL)) 			? ^{	theGetterIMPBlock = SIMPLE_GETTER(bool, Bool); 						theSetterIMPBlock = SIMPLE_SETTER(bool, Bool); 		}():
			strcmp(theType, @encode(short)) 			? ^{	theGetterIMPBlock = SIMPLE_GETTER(short, Short); 					theSetterIMPBlock = SIMPLE_SETTER(short, Short); 	}():
			strcmp(theType, @encode(int))				? ^{	theGetterIMPBlock = SIMPLE_GETTER(int, Int);							theSetterIMPBlock = SIMPLE_SETTER(int, Int);    	}():
			strcmp(theType, @encode(unsigned int)) ? ^{	theGetterIMPBlock = SIMPLE_GETTER(unsignedInt, UnsignedInt); 	theSetterIMPBlock = SIMPLE_SETTER(unsigned int, UnsignedInt); }():
			strcmp(theType, @encode(long)) 			? ^{	theGetterIMPBlock = SIMPLE_GETTER(long, Long);						theSetterIMPBlock = SIMPLE_SETTER(long, Long);		}():
			strcmp(theType, @encode(float)) 			? ^{	theGetterIMPBlock = SIMPLE_GETTER(float, Float);					theSetterIMPBlock = SIMPLE_SETTER(float, Float);	}():
			strcmp(theType, @encode(double)) 		? ^{	theGetterIMPBlock = SIMPLE_GETTER(double, Double);					theSetterIMPBlock = SIMPLE_SETTER(double, Double);	}():
			^{ NSAssert1(NO, @"Unknown simple type: '%s'", theType); }();
		}
		else if (theType[0] == '{') {
#if TARGET_OS_IPHONE == 0
			if (strcmp(theType, @encode(NSPoint)) == 0) {	theGetterIMPBlock = STRUCT_GETTER(NSPoint);	theSetterIMPBlock = STRUCT_SETTER(NSPoint);	}
#endif
		}
		NSAssert(theGetterIMPBlock != NULL, @"No getter implementation block");
		NSAssert(inGetter != NULL, @"No getter block");
		IMP theGetterFunctionPtr = imp_implementationWithBlock((__bridge id)((__bridge void *)theGetterIMPBlock));
		class_addMethod(inClass, NSSelectorFromString(theGetterName), theGetterFunctionPtr, [theGetterType UTF8String]);
		if (theReadonlyFlag == NO) {
			NSAssert(theSetterIMPBlock != NULL, @"No setter implementation block");
			NSAssert(inSetter != NULL, @"No setter block");
			IMP theSetterFunctionPtr = imp_implementationWithBlock((__bridge id)((__bridge void *)theSetterIMPBlock));
			class_addMethod(inClass, NSSelectorFromString(theSetterName), theSetterFunctionPtr, [theSetterType UTF8String]);
		}
		theResult = YES;
	}
	theAttributes != NULL ?	free(theAttributes) : nil;
	return theResult;
}

@end

@implementation NSObject (DynamicProperties)

//+ (BOOL) addCatchallPropertyWithGetterAndSetter:@[PGETTER)g,...; {	va_list args; va_start(args,g);
//	 for( int i = 0; i < count; i++ ) {	value = va_arg(args, NSNumber *);
// 	retval += [value doubleValue];
//     }
//     va_end(args);
//    return [NSNumber numberWithDouble:retval];
//}
+ (BOOL) addCatchallPropertyWithGetter:  (PGETTER)g setter:(PSETTER)s	{ return [CPropertyFactory.new configure:self getter:g setter:s error:nil];							}
+ (BOOL) addProperty:(NSString*)p getter:(PGETTER)g setter:(PSETTER)s	{ return [CPropertyFactory.new configure:self 		 propertyName:p getter:g setter:s error:nil]; }
- (BOOL) addProperty:(NSString*)p getter:(PGETTER)g setter:(PSETTER)s	{ return [CPropertyFactory.new configure:self.class propertyName:p getter:g setter:s error:nil]; }


+ (NSArray*) dynamicPropertyNames {		unsigned int i, count = 0;

	objc_property_t *properties = class_copyPropertyList( self, &count );
	if ( count == 0 ) return free(properties), nil; else 	NSLog(@"property count: %i", count);
	NSMutableArray *list = [NSMutableArray array];

	for ( i = 0; i < count; i++ ) {
		BOOL theDynamicFlag = NO;//,  theReadonlyFlag = NO;
//		const char *theType = NULL;
		unsigned int theAttributeCount = 0;
		objc_property_attribute_t *theAttributes = property_copyAttributeList(properties[i], &theAttributeCount);
		// See http://developer.apple.com/library/ios/#DOCUMENTATION/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html for all flags.
		for (unsigned int theAttributeIndex = 0; theAttributeIndex != theAttributeCount; ++theAttributeIndex) {
			if (strlen(theAttributes[theAttributeIndex].name) == 1) {
				switch (theAttributes[theAttributeIndex].name[0]) {
					case 'D': theDynamicFlag = YES;											break;
					default: break;
//					case 'T': theType = theAttributes[theAttributeIndex].value;		break;
//					case 'R': theReadonlyFlag = YES;											break;
//					case 'N':																		break; 	// theNonAtomicFlag = YES;
				}
			}
		}
		if (theDynamicFlag == YES)//  && theType != NULL) {	NSString *thePropertyName, *theGetterName, *theSetterName, *theGetterType, *theSetterType;
			[list addObject:[NSString stringWithUTF8String:property_getName(properties[i])]];
	}
//	if (properties != NULL)	free(properties);
	return [list copy];
}

@end

//
//  CPropertyFactory.m
//  Test
//
//  Created by Jonathan Wight on 10/3/11.
//  Copyright 2011 Jonathan Wight. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY 2011 TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 2011 TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of 2011 toxicsoftware.com.



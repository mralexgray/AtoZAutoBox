
#import "AtoZAutoBox.h"

id _box			( const void *value, const char *encoding)	{
    // file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.DeveloperTools.docset/Contents/Resources/Documents/documentation/DeveloperTools/gcc-4.0.1/gcc/Type-encoding.html
    char e = encoding[0]=='r' ? encoding[1] : encoding[0]; // ignore 'const' modifier
    switch( e ) {
        case 'c':   return @(*(char*)					value);
        case 'C':   return [NSNumber numberWithUnsignedChar: *(char*)value];
        case 's':   return @(*(short*)					value);
        case 'S':   return @(*(unsigned short*)		value);
        case 'i':   return @(*(int*)					value);
        case 'I':   return @(*(unsigned int*)		value);
        case 'l':   return @(*(long*)					value);
        case 'L':   return @(*(unsigned long*)		value);
        case 'q':   return @(*(long long*)			value);
        case 'Q':   return @(*(unsigned long long*)value);
        case 'f':   return @(*(float*)					value);
        case 'd':   return @(*(double*)				value);
        case '*':   return @(*(char**)					value);
        case '@':   return (__bridge id)				value;
        default:    return [NSValue value: value withObjCType: encoding];
    }
}
id _cast			( Class requiredClass, id object )				{
    if( object && ! [object isKindOfClass: requiredClass] )
        [NSException raise: NSInvalidArgumentException format: @"%@ required, but got %@ %p",
         requiredClass,[object class],object];
    return object;
}
id _castNotNil	( Class requiredClass, id object )				{
    if( ! [object isKindOfClass: requiredClass] )
        [NSException raise: NSInvalidArgumentException format: @"%@ required, but got %@ %p",
         requiredClass,[object class],object];
    return object;
}
id _castIf		( Class requiredClass, id object )				{
    if( object && ! [object isKindOfClass: requiredClass] )
        object = nil;
    return object;
}

//NSArray* _castArrayOf(Class itemClass, NSArray *a)	{ id item; foreach( item, $cast(NSArray,a) )_cast(itemClass,item); return a;}


void setObj		 	( id *var, id value ){ if( value != *var ) *var = value;	}
BOOL ifSetObj	 	( id *var, id value ){ return  value != *var && ![value isEqual: *var] ? *var = value, YES : NO;	}
void setString	 	( NSString **var, NSString *value )	{   if( value != *var )  *var = [value copy];	}
BOOL ifSetString	( NSString **var, NSString *value ){
    if( value != *var && ![value isEqualToString: *var] ) {
        *var = [value copy];
        return YES;
    } else {
        return NO;
    }
}
NSString * $string( const char *utf8Str ){ return utf8Str ? @(utf8Str) : nil; }
//based off http://www.dribin.org/dave/blog/archives/2008/09/22/convert_to_nsstring/
static     BOOL   TypeCodeIsCharArray						(const char *typeCode) {

	size_t                    len = strlen(typeCode);			if (len <= 2) return NO;
	size_t         lastCharOffset = 				 len - 1,
		    secondToLastCharOffset = lastCharOffset - 1;
	BOOL              isCharArray = typeCode[0] == '['
			  && typeCode[secondToLastCharOffset] == 'c'
			  && 			 typeCode[lastCharOffset] == ']';
	for (int i = 1; i < secondToLastCharOffset; i++) isCharArray = isCharArray && isdigit(typeCode[i]);
	return isCharArray;
}
//since BOOL is #defined as a signed char, we treat the value as a BOOL if it is exactly YES or NO, and a char otherwise.
static NSString * StringFromBoolOrCharValue           (BOOL boolOrCharvalue) {

	return 	boolOrCharvalue == YES 	? @"YES" :
				boolOrCharvalue == NO	? @"NO"  :	[NSString stringWithFormat:@"'%c'", boolOrCharvalue];
}
static NSString * StringFromFourCharCodeOrUnsignedInt32(FourCharCode fourcc) {

	return [NSString stringWithFormat:@"%u ('%c%c%c%c')", fourcc, (fourcc >> 24) & 0xFF, (fourcc >> 16) & 0xFF, (fourcc >> 8) & 0xFF, fourcc & 0xFF];
}
static NSString * StringFromNSDecimalWithCurrentLocal		    (NSDecimal dcm) { return NSDecimalString(&dcm, NSLocale.currentLocale);	}

NSString * DDToStringFromTypeAndValue (const char*typeCode, void*value) {

#define IF_TYPE_MATCHES_INTERPRET_WITH(typeToMatch, func)  	\
			if (strcmp(typeCode,@encode(typeToMatch)) == 0)		\
				return (func)(*(typeToMatch*)value)

#if	 TARGET_OS_IPHONE
	IF_TYPE_MATCHES_INTERPRET_WITH (   CGPoint, NSStringFromCGPoint						);
	IF_TYPE_MATCHES_INTERPRET_WITH (    CGSize, NSStringFromCGSize							);
	IF_TYPE_MATCHES_INTERPRET_WITH (	   CGRect, NSStringFromCGRect							);
#else
	IF_TYPE_MATCHES_INTERPRET_WITH (   NSPoint, NSStringFromPoint							);
	IF_TYPE_MATCHES_INTERPRET_WITH (    NSSize, NSStringFromSize 							);
	IF_TYPE_MATCHES_INTERPRET_WITH (	   NSRect, NSStringFromRect							);
#endif
	IF_TYPE_MATCHES_INTERPRET_WITH (   NSRange, NSStringFromRange							);
	IF_TYPE_MATCHES_INTERPRET_WITH ( 	 Class, NSStringFromClass							);
	IF_TYPE_MATCHES_INTERPRET_WITH ( 	   SEL, NSStringFromSelector						);
	IF_TYPE_MATCHES_INTERPRET_WITH ( 	  BOOL, StringFromBoolOrCharValue	 		);
	IF_TYPE_MATCHES_INTERPRET_WITH ( NSDecimal, StringFromNSDecimalWithCurrentLocal	);

#define IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(typeToMatch, formatString) 			\
	if (strcmp(typeCode, @encode(typeToMatch)) == 0) 										\
		return [NSString stringWithFormat:formatString, (*(typeToMatch *)value)]

	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 			CFStringRef, @"%@");	//CFStringRef is toll-free bridged to NSString*
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 			 CFArrayRef, @"%@");	//CFArrayRef is toll-free bridged to NSArray*
	IF_TYPE_MATCHES_INTERPRET_WITH		  ( 		  FourCharCode, StringFromFourCharCodeOrUnsignedInt32);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (           long long, @"%lld"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (  unsigned long long, @"%llu"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 					float, @"%f"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 				  double, @"%f"		);
#if __has_feature(objc_arc)
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (__unsafe_unretained id, @"%@"		);
#else /* not __has_feature(objc_arc) */
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					   id, @"%@"		);
#endif
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					short, @"%hi"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (      unsigned short, @"%hu"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					  int, @"%i"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (				unsigned, @"%u"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					 long, @"%li"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (			long double, @"%Lf"		);	//WARNING on older versions of OS X, @encode(long double) == @encode(double)
	//C-strings
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (				   char*, @"%s"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (			const char*, @"%s"		);

	if (TypeCodeIsCharArray(typeCode)) return [NSString stringWithFormat:@"%s", (char *)value];

	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					void*, @"(void*)%p");

	//This is a hack to print out CLLocationCoordinate2D, without needing to #import <CoreLocation/CoreLocation.h>. A CLLocationCoordinate2D is a struct made up of 2 doubles. We detect it by hard-coding the result of @encode(CLLocationCoordinate2D). We get at the fields by treating it like an array of doubles, which it is identical to in memory.//@encode(CLLocationCoordinate2D) 	//we don't know how to convert this typecode into an NSString
	return strcmp(typeCode, "{?=dd}") == 0 ? [NSString stringWithFormat:@"{latitude=%g,longitude=%g}", ((double *)value)[0], ((double *)value)[1]] : nil;
}

/*
id AZ_AutoBox_Helper (const char*typeCode, void*value) {

#define IF_TYPE_MATCHES_BOX_WITH(typeToMatch, func)  	\
			if (strcmp(typeCode,@encode(typeToMatch)) == 0)		\
				return (func)(*(typeToMatch*)value)

#if	 TARGET_OS_IPHONE
	IF_TYPE_MATCHES_BOX_WITH (   CGPoint, NSStringFromCGPoint						);
	IF_TYPE_MATCHES_BOX_WITH (    CGSize, NSStringFromCGSize							);
	IF_TYPE_MATCHES_BOX_WITH (	   CGRect, NSStringFromCGRect							);
#else
	IF_TYPE_MATCHES_BOX_WITH (   NSPoint, AZVpoint	);
	IF_TYPE_MATCHES_BOX_WITH (    NSSize, AZVsize	);
	IF_TYPE_MATCHES_BOX_WITH (	   NSRect, AZVrect	);
#endif
	IF_TYPE_MATCHES_BOX_WITH (   NSRange, AZVrng		);
	IF_TYPE_MATCHES_BOX_WITH ( 	 Class, NSStringFromClass							);
	IF_TYPE_MATCHES_BOX_WITH ( 	   SEL, NSStringFromSelector						);
	IF_TYPE_MATCHES_BOX_WITH ( 	  BOOL, StringFromBoolOrCharValue	 		);
	IF_TYPE_MATCHES_BOX_WITH ( NSDecimal, StringFromNSDecimalWithCurrentLocal	);

#define IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT(typeToMatch, formatString) 			\
	if (strcmp(typeCode, @encode(typeToMatch)) == 0) 										\
		return [NSString stringWithFormat:formatString, (*(typeToMatch *)value)]

	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 			CFStringRef, @"%@");	//CFStringRef is toll-free bridged to NSString*
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 			 CFArrayRef, @"%@");	//CFArrayRef is toll-free bridged to NSArray*
	IF_TYPE_MATCHES_INTERPRET_WITH		  ( 		  FourCharCode, StringFromFourCharCodeOrUnsignedInt32);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (           long long, @"%lld"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (  unsigned long long, @"%llu"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 					float, @"%f"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT ( 				  double, @"%f"		);
#if __has_feature(objc_arc)
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (__unsafe_unretained id, @"%@"		);
#else / * not __has_feature(objc_arc) * /
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					   id, @"%@"		);
#endif
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					short, @"%hi"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (      unsigned short, @"%hu"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					  int, @"%i"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (				unsigned, @"%u"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					 long, @"%li"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (			long double, @"%Lf"		);	//WARNING on older versions of OS X, @encode(long double) == @encode(double)
	//C-strings
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (				   char*, @"%s"		);
	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (			const char*, @"%s"		);

	if (TypeCodeIsCharArray(typeCode)) return [NSString stringWithFormat:@"%s", (char *)value];

	IF_TYPE_MATCHES_INTERPRET_WITH_FORMAT (					void*, @"(void*)%p");

	//This is a hack to print out CLLocationCoordinate2D, without needing to #import <CoreLocation/CoreLocation.h>. A CLLocationCoordinate2D is a struct made up of 2 doubles. We detect it by hard-coding the result of @encode(CLLocationCoordinate2D). We get at the fields by treating it like an array of doubles, which it is identical to in memory.//@encode(CLLocationCoordinate2D) 	//we don't know how to convert this typecode into an NSString
	return strcmp(typeCode, "{?=dd}") == 0 ? [NSString stringWithFormat:@"{latitude=%g,longitude=%g}", ((double *)value)[0], ((double *)value)[1]] : nil;
}

*/
NSString * DDNSStringFromBOOL(BOOL b)
{
    return b ? @"YES" : @"NO";
}

NSString * DDToStringFromTypeAndValueAlt(const char * typeCode, void * value)
{
    if (strcmp(typeCode, @encode(NSPoint)) == 0)
    {
        return NSStringFromPoint(*(NSPoint *)value);
    }
    else if (strcmp(typeCode, @encode(NSSize)) == 0)
    {
        return NSStringFromSize(*(NSSize *)value);
    }
    else if (strcmp(typeCode, @encode(NSRect)) == 0)
    {
        return NSStringFromRect(*(NSRect *)value);
    }
    else if (strcmp(typeCode, @encode(Class)) == 0)
    {
        return NSStringFromClass(*(Class *)value);
    }
    else if (strcmp(typeCode, @encode(SEL)) == 0)
    {
        return NSStringFromSelector(*(SEL *)value);
    }
    else if (strcmp(typeCode, @encode(NSRange)) == 0)
    {
        return NSStringFromRange(*(NSRange *)value);
    }
    else if (strcmp(typeCode, @encode(id)) == 0)
    {
        return ddsprintf(@"%@", value);//*(id *)value);
    }
    else if (strcmp(typeCode, @encode(BOOL)) == 0)
    {
        return DDNSStringFromBOOL(*(BOOL *)value);
    }
        
    return ddsprintf(@"? <%s>", typeCode);
}


//NSValue * AZVpoint	(NSPoint pnt)		{ return [NSValue valueWithPoint:pnt];			}
//NSValue * AZVrect 	(NSRect rect) 		{ return [NSValue valueWithRect: rect]; 		}
//NSValue * AZVsize 	(NSSize size) 		{ return [NSValue valueWithSize: size]; 		}
//NSValue * AZV3d	 	(CATransform3D t) { return [NSValue valueWithCATransform3D:t]; }
//NSValue * AZVrng	 	(NSRange rng) 		{ return [NSValue valueWithRange:rng]; 		}


@implementation NSObject (AtoZAutoBox)	@dynamic box;
- (AtoZAutoBox*) box 					{	return objc_getAssociatedObject(self,(__bridge const void*)@"AtoZAutoBox");	}
- (void) setBox:(AtoZAutoBox*)box 	{
	objc_setAssociatedObject(self,(__bridge const void*)@"AtoZAutoBox", box, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}	@end

@implementation AtoZAutoBox

- (void) dynamicallySubclassBox:(AtoZAutoBox*)box {
  const char * prefix = self.typeCode.UTF8String;//"CHLayoutAutoremove_";
  Class boxClass = [self class];
  NSString * className = NSStringFromClass(boxClass);
  if (strncmp(prefix, [className UTF8String], strlen(prefix)) == 0) { return; }
  NSString * subclassName = [NSString stringWithFormat:@"%s%@", prefix, className];
  Class subclass = NSClassFromString(subclassName);

  if (subclass == nil) {
    subclass = objc_allocateClassPair(boxClass, subclassName.UTF8String, 0);
    if (subclass != nil) {
      IMP dealloc = class_getMethodImplementation(self.class, @selector(dynamicDealloc));

      class_addMethod(subclass, @selector(dealloc), dealloc, "v@:");
      objc_registerClassPair(subclass);
    }
  }

  if (subclass != nil) {
    object_setClass(view, subclass);
  }
}

+ (id)autoBoxType:(const char*)encoding value:(const void*)value {
	AtoZAutoBox *b = AtoZAutoBox.new;
	// file:///Developer/Documentation/DocSets/com.apple.ADC_Reference_Library.DeveloperTools.docset/Contents/Resources/Documents/documentation/DeveloperTools/gcc-4.0.1/gcc/Type-encoding.html
   char e = encoding[0]=='r' ? encoding[1] : encoding[0]; // ignore 'const' modifier
   NSObject* x =
   	e == 'c' ? @(*(char*)					value) :
      e == 's' ? @(*(short*)					value) :
      e == 'S' ? @(*(unsigned short*)		value) :
      e == 'i' ? @(*(int*)						value) :
      e == 'I' ? @(*(unsigned int*)			value) :
      e == 'l' ? @(*(long*)					value) :
      e == 'L' ? @(*(unsigned long*)		value) :
      e == 'q' ? @(*(long long*)				value) :
      e == 'Q' ? @(*(unsigned long long*)	value) :
      e == 'f' ? @(*(float*)					value) :
      e == 'd' ? @(*(double*)					value) :
      e == '*' ? @(*(char**)					value) :
      e == '@' ? (__bridge id)				value  :
		e == 'C' ? [NSNumber numberWithUnsignedChar: *(char*)value]
					: [NSValue value:&value withObjCType:encoding];
	b.typeCode = [NSString stringWithUTF8String:encoding];
	NSLog(@"encoded with %@", b.typeCode);
	x.box = b;
	return x;
}
- (void*) rawValue {

	if (self.isAnObject) return (__bridge void*)self.value;
	NSUInteger bufferSize = 0;
	NSGetSizeAndAlignment([self.value objCType], &bufferSize, NULL);
	void* buffer = malloc(bufferSize);
	[self.value getValue:buffer];
	return buffer;
}

- (BOOL) isAnObject {  return [_typeCode isEqualToString:@"@"]; }
- (NSString *)description { return [NSString stringWithFormat:@"%@.. v:%@ t:%@ (%@) boxer:%@ unboxer:%@ isAnObject:%@", NSStringFromClass(self.class), self.value, self.typeCode, self.typeDescription, NSStringFromSelector(self.boxer), NSStringFromSelector(self.unboxer), self.isAnObject ? @"YES" : @"NO"];   }
- (NSString*) typeDescription {
	static NSDictionary *typeD = nil;  if (!typeD) typeD =
	@{	@"c":@"A char.",@"i": @"An int.", @"s":@"A short.", @"l":@"A long. \"l\" is treated as a 32-bit quantity on 64-bit programs.",
		@"q":@"A long long", @"C":@"An unsigned char.", @"I":@"An unsigned int.", @"S":@"An unsigned short.",
		@"L":@"An unsigned long.", @"Q":@"An unsigned long long.", @"f": @"A float.", @"d": @"A double.",
		@"B":@"A C++ bool or a C99 _Bool.", @"v":@"A void.", @"*": @"A character string (char *).",
		@"@":@"An object (whether statically typed or typed id).", @"#": @"A class object (Class).",
		@":":@"A method selector (SEL)", @"[": @"[array type] - An array.",
		@"{":@"{name=type...} A structure",		@"(":@"(name=type...) A union.",
		@"b":@"bnum - A bit field of num bits",@"^":@"^type = A pointer to type..",
		@"?":@"An unknown type (among other things, this code is used for function pointers)"};
	NSString *code = [self.typeCode substringWithRange:NSMakeRange(0,1)];
	return [typeD objectForKey:code] ?: @"ERROR..  typecode ISSUE with autobox!";

}
@end

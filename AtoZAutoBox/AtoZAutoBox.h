
#import <objc/runtime.h>

/** OVERVIEW **/
/*  */

@interface 		  		 AtoZAutoBox : NSObject
@property (readonly)     NSString * typeDescription;  // Just a "cute" description.
@property (strong)       NSString * typeCode;			// Secret identity.
@property (weak)	 				 id   value;  				// NSNumber / NSString / NSValue.
@property (readonly) 		  BOOL   isAnObject;			// Based on type.
@property (readonly) 	      SEL   boxer,
											   unboxer;				// These are hardcoded by "type".
- (void*) rawValue;
+ (id) autoBoxType:(const char*)encoding
		 		 value:(const void*)value;
@end

@interface 				 	 NSObject 	(AtoZAutoBox)  	// Convenience for associating the box.
@property (readwrite) AtoZAutoBox * box;																					@end


#define DESTRUCTIFIER(_x_) _Generic((_x_), 		 \
	NSRect			: [NSValue valueWithRect:_x_], \
	default 			: _x_)

// Does the raw gruntwork via the cookie "_generic Macro"
#define OBJECTIFIER(_x_) _Generic((_x_), 								\
	id					: _x_,													\
	char*				: [NSString stringWithUTF8String:_x_],			\
	BOOL				: [NSNumber numberWithBool:_x_],					\
	default			: DESTRUCTIFIER(_x_))

#define   AUTOBOX(_z_)	[AtoZAutoBox autoBoxWith:@encode(__typeof__(_z_)) value:_z_]

/// encoded:@encode(__typeof__(_z_))]]

  //(const void *)
  
#define AUTOUNBOX(_x_) 	[_x_ performSelector:[_x_ unboxer]]

//({  id _y_ = OBJECTIFIER(_z_); _y_ = _y_ ?: DESTRUCTIFIER(_z_); 

#define $object(VAL)        ({__typeof(VAL) v=(VAL); _box(&v,@encode(__typeof(v)));})

/*  	char: [NSString stringWithUTF8String:_x_],	\
	signed char: [NSNumber numberWithChar:_x_],	CGRect : [NSValue valueWithRect:_x_],		*/

/*
	NSO *x = OBJECTIFY(YES);	LOG_EXPR([x class]);			LOG_EXPR(x);	LOG_EXPR(x.encodedEncoding);
		 								[x class] = __NSCFNumber	x = 1				x.encodedEncoding = c
*/
//#define OBJECTIFY(_x_)  ({	NSObject* _y_ = OBJECTIFIER(_x_);									\
//	_y_.encodedEncoding = [NSString stringWithUTF8String:@encode(typeof(_x_))]; _y_; })



//#define ENCODEINFO(_TYPE_, _ENCODE_SEL_, _DECODE_SEL_) @{@"type":NSString
///* Get the name of a type */
//#define typename(x) _Generic((x), _Bool: "_Bool", \
//    char: @"char",     					 signed char: @"signed char",     unsigned char: @"unsigned char", 		\
//    short int: @"short int",	unsigned short int: @"unsigned short int", 		 int: @"int", 						\
//	 unsigned int: @"unsigned int", 	    long int: "long int",    unsigned long int: "unsigned long int", 		\
//    long long int: "long long int",	       int *: "pointer to int",							      unsigned long long int: "unsigned long long int", 	\
//    float: "float", \
//    double: "double", \
//    long double: "long double", \
//    char *: "pointer to char", \
//    void *: "pointer to void", \
//     \
//    default: "other")
//NS_INLINE void test_typename(void) {
//   size_t s;	ptrdiff_t p;   intmax_t i;  int ai[3] = {0};
//	printf("size_t is '%s'\n", typename(s));
//   printf("ptrdiff_t is '%s'\n", typename(p));
//   printf("intmax_t is '%s'\n", typename(i));
// 
//   printf("character constant is '%s'\n", typename('0'));
//   printf("0x7FFFFFFF is '%s'\n", typename(0x7FFFFFFF));
//   printf("0xFFFFFFFF is '%s'\n", typename(0xFFFFFFFF));
//   printf("0x7FFFFFFFU is '%s'\n", typename(0x7FFFFFFFU));
//   printf("array of int is '%s'\n", typename(ai));
//}

//FOUNDATION_EXPORT NSValue * AZVpoint	(NSPoint pnt);
//FOUNDATION_EXPORT NSValue * AZVrect 	(NSRect rect);
//FOUNDATION_EXPORT NSValue * AZVsize 	(NSSize size);
//FOUNDATION_EXPORT NSValue * AZV3d	 	(CATransform3D t);
//FOUNDATION_EXPORT NSValue * AZVrng	 	(NSRange rng);

//#define  AZVinstall(p) 	[NSVAL valueWithInstallStatus: p]
//#define  	AZVposi(p) 	[NSVAL      valueWithPosition: p]
//
//#define 		  AZVpoints(x,y) 	[NSVAL 	valueWithPoint:NSMakePoint(x,y)]
//#define AZVrectMake(x,y,w,h) 	[NSVAL 			 valueWithRect:NSMakeRect(x,y,w,h)]


#define ddsprintf(FORMAT, ARGS... )  [NSString stringWithFormat: (FORMAT), ARGS]

NSString * DDToStringFromTypeAndValue(const char * typeCode, void * value);

#define DDToNString(_X_) ({typeof(_X_) _Y_ = (_X_);\
    DDToStringFromTypeAndValue(@encode(typeof(_X_)), &_Y_);})

#define IS_OBJECT(T) _Generic( (T), id: YES, default: NO)
#define 	LOG_EXPR(_X_) 		do{	__typeof__(_X_) _Y_ = (_X_); NSS*_STR_;					\
											const char * _TYPE_CODE_ = @encode(__typeof__(_X_));	\
			(_STR_= DDToStringFromTypeAndValue(_TYPE_CODE_, &_Y_))							\
			?	NSLog(@"%s = %@", #_X_, _STR_) 															\
			:	NSLog(@"Unknown _TYPE_CODE_:\"%s\" for expr:%s in func:%s file:%s line:%d",\
					_TYPE_CODE_, #_X_, __func__, __FILE__, __LINE__); }while (0)


#define 	AutoBox(_X_) 		do{	__typeof__(_X_) _Y_ = (_X_); NSS*_STR_;					\
											const char * _TYPE_CODE_ = @encode(__typeof__(_X_));	\
			(_STR_= DDToStringFromTypeAndValue(_TYPE_CODE_, &_Y_))							\
			?	NSLog(@"%s = %@", #_X_, _STR_) 															\
			:	NSLog(@"Unknown _TYPE_CODE_:\"%s\" for expr:%s in func:%s file:%s line:%d",\
					_TYPE_CODE_, #_X_, __func__, __FILE__, __LINE__); }while (0)

//#define 	AutoUnBox(_TYPE_CODE_ 		do{	__typeof__(_X_) _Y_ = (_X_); NSS*_STR_;					\
//											const char * _TYPE_CODE_ = @encode(__typeof__(_X_));	\
//			(_STR_= VTPG_DDToStringFromTypeAndValue(_TYPE_CODE_, &_Y_))							\
//			?	NSLog(@"%s = %@", #_X_, _STR_) 															\
//			:	NSLog(@"Unknown _TYPE_CODE_:\"%s\" for expr:%s in func:%s file:%s line:%d",\
//					_TYPE_CODE_, #_X_, __func__, __FILE__, __LINE__); }while (0)

/**
 .h		@interface UIView (DHStyleManager)			@property (nonatomic, copy) NSString* styleName;			@end
 .m		@implementation UIView (DHStyleManager)	ADD_DYNAMIC_PROPERTY(NSString*,styleName,setStyleName);	@end
 */
#define ADD_DYNAMIC_PROPERTY(PROPERTY_TYPE,PROPERTY_NAME,SETTER_NAME) 	 												\
																																				\
@dynamic PROPERTY_NAME ; 																												\
static char kProperty##PROPERTY_NAME; 																								\
- ( PROPERTY_TYPE ) PROPERTY_NAME { 																								\
	id retVal = objc_getAssociatedObject(self,&(kProperty##PROPERTY_NAME ));											\
	return (strcmp(@encode(PROPERTY_TYPE),@encode(BOOL))	  == 0) ? (BOOL)		[(NSNumber*)retVal boolValue] :	\
/*			 (strcmp(@encode(PROPERTY_TYPE),@encode(CGPoint)) == 0) ? (CGPoint)	[(NSValue*)retVal pointValue] :
			 (strcmp(@encode(PROPERTY_TYPE),@encode(CGSize))  == 0) ? (CGSize)	[(NSValue*)retVal  sizeValue] :
			 (strcmp(@encode(PROPERTY_TYPE),@encode(CGRect))  == 0) ? (CGRect)	[(NSValue*)retVal  rectValue] :
*/\
		 (PROPERTY_TYPE) retVal; 				\
}				\
- (void) SETTER_NAME :( PROPERTY_TYPE ) PROPERTY_NAME	{ 			\
	BOOL isObject = IS_OBJECT(PROPERTY_NAME); id setVal = nil;	\
	if (!isObject) { \
	setVal = strcmp(@encode(PROPERTY_TYPE),@encode(BOOL))	== 0 ? [NSNumber numberWithBool:PROPERTY_NAME] :			\
/*						strcmp(@encode(PROPERTY_TYPE),@encode(CGSize))  == 0	?	[NSValue valueWithSize: PROPERTY_NAME] :	\
				 	strcmp(@encode(PROPERTY_TYPE),@encode(CGRect))	== 0	?	[NSValue valueWithRect: PROPERTY_NAME] :	\
						strcmp(@encode(PROPERTY_TYPE),@encode(CGPoint))	== 0	?	[NSValue valueWithPoint:PROPERTY_NAME] :	\
*/\
	@(PROPERTY_NAME);																												\
	}	\
	if (isObject) {\
		objc_setAssociatedObject(self, &kProperty##PROPERTY_NAME , PROPERTY_NAME, OBJC_ASSOCIATION_RETAIN_NONATOMIC ); \
	}			\
	else { objc_setAssociatedObject(self, &kProperty##PROPERTY_NAME , setVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC ); }			\
}




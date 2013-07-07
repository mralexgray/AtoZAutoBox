
#import <Foundation/Foundation.h>
#import <objc/runtime.h>


#define SIMPLE_GETTER(T, T2) ^(id _self)         { return ([inGetter(_self, thePropertyName) T ## Value]); };
#define SIMPLE_SETTER(T, T2) ^(id _self, T value){ inSetter(_self, thePropertyName, [NSNumber numberWith ## T2:value]); };
#define STRUCT_GETTER(T)     ^(id _self) 			 { T value; [inGetter(_self, thePropertyName) getValue:&value]; return (value); };
#define STRUCT_SETTER(T)     ^(id _self, T value){ inSetter(_self, thePropertyName, [NSValue valueWithBytes:&value objCType:@encode(T)]); };

#define PGETTER 			id (^)(id _self, NSString *key)
#define PSETTER 		 void (^)(id _self, NSString *key, id value)


												/* USAGE -
+ (void)initialize  {	[self addCatchallPropertyWithGetter:  ^id(id _self, NSS *k) {
										return objc_getAssociatedObject       ( _self, (__bridge const void *)k ); 
								}			  						setter: ^(id _self, NSS *k, id v) {
										objc_setAssociatedObject(_self, ( __bridge const void*) k, v, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
								}];
*/

@interface NSObject (DynamicProperties)

+ (NSArray*) dynamicPropertyNames;
//+ (BOOL)addCatchallPropertyWithGet	terAndSetter:(id(^)(id _self, NSString*key))getter,...;

+ (BOOL)addCatchallPropertyWithGetter:(  id(^)(id _self, NSString*key))g
									 	 setter:(void(^)(id _self, NSString*key, id value))s;

- (BOOL)addProperty:(NSString*)p
	       	 getter:(  id(^)(id _self, NSString*key))g
			 	 setter:(void(^)(id _self, NSString*key, id value))s;

+ (BOOL)addProperty:(NSString*)p
	       	 getter:(  id(^)(id _self, NSString*key))g
			 	 setter:(void(^)(id _self, NSString*key, id value))s;
@end

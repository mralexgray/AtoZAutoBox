#import <Foundation/Foundation.h>

//It actually works best if you create a category on NSObject and just drop that method straight in there, that way you can call it on any object.

@interface NSObject (Primitives)
- (void *)performSelector:(SEL)selector withValue:(void *)value;
@end

//Here are some examples. First of all, let’s just assume we have a class with the following methods:

//	- (void)doSomethingWithFloat:(float)f;  // Example 1
//	- (int)addOne:(int)i;				   // Example 2

// Example 1
//	float value = 7.2661; // Create a float
//	float *height = &value; // Create a _pointer_ to the float (a floater?)
//	[self performSelector:@selector(doSomethingWithFloat:) withValue:height]; // Now pass the pointer to the float
//	free(height); // Don't forget to free the pointer!

// Example 2
//	int ten = 10; // As above
//	int *i = &ten;
//	int *result = [self performSelector:@selector(addOne:) withValue:i]; // Returns a __pointer__ to the int
//	NSLog(@"result is %d", *result); // Remember that it's a pointer, so keep the *!
//	free(result);

/*  Things get a little more complicated when dealing with methods that return objects, as opposed to primitives or structs. For primitives, our performSelector:withValue: returns a pointer to the method’s return value (i.e. a primitive). However, when the underlying method returns an object, it’s actually returning a pointer to the object. So that means that when our code runs, it ends up returning a pointer to a pointer to the object (i.e. a void **), which you need to handle appropriately. If that wasn’t tricky enough, if you’re using ARC, you also need to bridge the void * pointer to bring it into Objective-C land.	*/

//	Here are some examples. Let’s assume you have a class with the following methods:
//	- (NSObject *)objectIfTrue:(BOOL)b;	 // Example 3
//	- (NSS*) strWithView:(UIView *)v;  // Example 4
//	Notice how both methods return objects (well, technically, pointers to objects, which is important!). We can now use performSelector:withValue: as follows:
/*
	BOOL y = YES; // Same as previously
	BOOL *valid = &y;
	void **p = [self performSelector:@selector(objectIfTrue:) withValue:valid]; // Returns a pointer to an NSObject (standard Objective-C behaviour)
	NSObject *obj = (__bridge NSObject *)*p; // bridge the pointer to Objective-C
	NSLog(@"object is %@", obj);
	free(p); */

//	Notice the return type of performSelector:withValue: is void **. In other words, a pointer to a pointer of type void (which means any type). We then reference the pointer once to get to a pointer to the actual object (to void * — a standard void pointer) and then use a bridged cast to convert that pointer to NSObject * which is a standard object (again, technically, a pointer to an object).

// 	Here’s one final example bringing everything to do with objects together, showing how to use performSelector:withValue: to call a selector on an object, with an object as an argument and as a return type:
/*
UIView *view = UIView.new;
void **p = [self performSelector:@selector(strWithView:) withValue:&view];
NSString *str = (__bridge NSString *)*p;
NSLog(@"string is %@", str);
free(p);
*/


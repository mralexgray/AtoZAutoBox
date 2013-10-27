//
//  CTObjectiveCRuntimeAdditions.h
//  CTObjectiveCRuntimeAdditions
//
//  Created by Oliver Letterer on 28.04.12.
//  Copyright (c) 2012 ebf. All rights reserved.
//

typedef void(^CTMethodEnumertor)(Class klass, Method method);
typedef BOOL(^CTClassTest)(Class subclass);

/**
 @abstract Swizzles originalSelector with newSelector.
 */
void class_swizzleSelector(Class klass, SEL originalSelector, SEL newSelector);

/**
 @abstract Swizzles all methods of a class with a given prefix with the corresponding SEL without the prefix. @selector(__hookedLoadView) will be swizzled with @selector(loadView). This method also swizzles klass methods with a given prefix.
 */
void class_swizzlesMethodsWithPrefix(Class klass, NSString *prefix);

/**
 @abstract Enumerate class methods.
 */
void class_enumerateMethodList(Class klass, CTMethodEnumertor enumerator);

/**
 @return A subclass of class which passes test.
 */
Class class_subclassPassingTest(Class klass, CTClassTest test);

/**
 @abstract Replaces implementation of method of originalSelector with block.
           if originalSelector's argument list is (id self, SEL _cmd, ...), then block's argument list must be (id self, ...)
 */
IMP class_replaceMethodWithBlock(Class klass, SEL originalSelector, id block);

/**
 Implements klass property at runtime which is backed by NSUserDefaults. This will use -[NSUserDefaults setObject:forKey:].
 */
void class_implementPropertyInUserDefaults(Class klass, NSString *propertyName, BOOL automaticSynchronizeUserDefaults);

/**
 Implements a property at runtime.
 */
void class_implementProperty(Class klass, NSString *propertyName);


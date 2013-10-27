//
//  CTObjectiveCRuntimeAdditions.m
//  CTObjectiveCRuntimeAdditions
//
//  Created by Oliver Letterer on 28.04.12.
//  Copyright (c) 2012 ebf. All rights reserved.
//

#import "AZRuntimeAdditions.h"
#import "AZBlockDescriptions.h"

void class_swizzleSelector(Class klass, SEL originalSelector, SEL newSelector)
{
    Method origMethod = class_getInstanceMethod(klass, originalSelector);
    Method newMethod = class_getInstanceMethod(klass, newSelector);
    if( class_addMethod(		klass, originalSelector, method_getImplementation(newMethod),  method_getTypeEncoding(newMethod )) ) {
        class_replaceMethod(	klass, newSelector, 		 method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(origMethod, newMethod);
    }
}

void class_swizzlesMethodsWithPrefix(Class klass, NSString *prefix)
{
    CTMethodEnumertor enumeratorBlock = ^(Class klass, Method method) {
        SEL methodSelector = method_getName(method);
        NSString *selectorString = NSStringFromSelector(methodSelector);
        
        if ([selectorString hasPrefix:prefix]) {
            NSMutableString *originalSelectorString = [selectorString stringByReplacingOccurrencesOfString:prefix withString:@"" options:NSLiteralSearch range:NSMakeRange(0, prefix.length)].mutableCopy;
            
            if (originalSelectorString.length > 0) {
                NSString *uppercaseFirstCharacter = [originalSelectorString substringToIndex:1];
                NSString *lowercaseFirstCharacter = uppercaseFirstCharacter.lowercaseString;
                
                [originalSelectorString replaceCharactersInRange:NSMakeRange(0, 1) withString:lowercaseFirstCharacter];
                
                SEL originalSelector = NSSelectorFromString(originalSelectorString);
                
                class_swizzleSelector(klass, originalSelector, methodSelector);
            }
        }
    };
    
    // swizzle instance methods
    class_enumerateMethodList(klass, enumeratorBlock);
    
    // swizzle class methods
    Class metaClass = objc_getMetaClass(class_getName(klass));
    class_enumerateMethodList(metaClass, enumeratorBlock);
}

void class_enumerateMethodList(Class klass, CTMethodEnumertor enumerator)
{
    if (!enumerator) return;
    
    static dispatch_queue_t queue = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("de.ebf.objc_runtime_additions.method_enumeration_queue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList(klass, &methodCount);
    
    dispatch_apply(methodCount, queue, ^(size_t index) {
        Method method = methods[index];
        enumerator(klass, method);
    });
    
    free(methods);
}

Class class_subclassPassingTest(Class klass, CTClassTest test)
{
    if (!test) return nil;
    
    static dispatch_queue_t queue = NULL;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("de.ebf.objc_runtime_additions.class_queue", DISPATCH_QUEUE_CONCURRENT);
    });
    
    unsigned int numberOfClasses = 0;
    Class *classList = objc_copyClassList(&numberOfClasses);
    
    __block Class testPassingClass = nil;
    
    dispatch_apply(numberOfClasses, queue, ^(size_t classIndex) {
        if (testPassingClass != nil) {
            return;
        }
        
        Class thisClass = classList[classIndex];
        Class superClass = thisClass;
        
        while ((superClass = class_getSuperclass(superClass))) {
            if (superClass == klass || thisClass == klass) {
                if (test(thisClass)) testPassingClass = thisClass;
            }
        }
    });
    
    // cleanup
    free(classList);
    
    return testPassingClass;
}

IMP class_replaceMethodWithBlock(Class klass, SEL originalSelector, id block)
{
    IMP newImplementation = imp_implementationWithBlock(block);
    
    Method method = class_getInstanceMethod(klass, originalSelector);
    return class_replaceMethod(klass, originalSelector, newImplementation, method_getTypeEncoding(method));
}

void class_implementPropertyInUserDefaults(Class klass, NSString *propertyName, BOOL automaticSynchronizeUserDefaults)
{
    NSString *userDefaultsKey = [NSString stringWithFormat:@"%@__%@", NSStringFromClass(klass), propertyName];
    
    SEL getter = NSSelectorFromString(propertyName);
    NSString *firstLetter = [propertyName substringToIndex:1];
    NSString *setterName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"set%@", firstLetter.uppercaseString]];
    setterName = [setterName stringByAppendingString:@":"];
    SEL setter = NSSelectorFromString(setterName);
    
    IMP getterImplementation = imp_implementationWithBlock(^id(id self) {
        // 1) try to read from cache
        return [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultsKey];
    });
    
    IMP setterImplementation = imp_implementationWithBlock(^(id self, id object) {
        if (!object) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:userDefaultsKey];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:object forKey:userDefaultsKey];
            
            if (automaticSynchronizeUserDefaults) {
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    });
    
    class_addMethod(klass, getter, getterImplementation, "@@:");
    class_addMethod(klass, setter, setterImplementation, "v@:@");
}

void class_implementProperty(Class klass, NSString *propertyName)
{
    NSCAssert(klass != Nil, @"class is required");
    NSCAssert(propertyName != nil, @"propertyName is required");
    
    objc_property_t property = class_getProperty(klass, propertyName.UTF8String);
    
    unsigned int count = 0;
    objc_property_attribute_t *attributes = property_copyAttributeList(property, &count);
    
    typedef enum {
        MemoryManagementAssign,
        MemoryManagementCopy,
        MemoryManagementRetain
    } MemoryManagement;
    
    MemoryManagement memoryManagement = MemoryManagementAssign;
    BOOL isNonatomic = NO;
    
    NSString *getterName = nil;
    NSString *setterName = nil;
    NSString *encoding = nil;
    
    for (NSUInteger i = 0; i < count; i++) {
        objc_property_attribute_t attribute = attributes[i];
        
        switch (attribute.name[0]) {
            case 'N':
                isNonatomic = YES;
                break;
            case '&':
                memoryManagement = MemoryManagementRetain;
                break;
            case 'C':
                memoryManagement = MemoryManagementCopy;
                break;
            case 'G':
                getterName = [NSString stringWithFormat:@"%s", attribute.value];
                break;
            case 'S':
                setterName = [NSString stringWithFormat:@"%s", attribute.value];
                break;
            case 'T':
                encoding = [NSString stringWithFormat:@"%s", attribute.value];
                break;
            case 'W':
                NSCAssert(NO, @"weak properties are not supported");
                break;
            default:
                break;
        }
    }
    
    if (!getterName) {
        getterName = propertyName;
    }
    
    if (!setterName) {
        NSString *firstLetter = [propertyName substringToIndex:1];
        setterName = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:[NSString stringWithFormat:@"set%@", firstLetter.uppercaseString]];
        setterName = [setterName stringByAppendingString:@":"];
    }
    
    NSCAssert([encoding characterAtIndex:0] != '{', @"structs are not supported");
    NSCAssert([encoding characterAtIndex:0] != '(', @"unions are not supported");
    
    SEL getter = NSSelectorFromString(getterName);
    SEL setter = NSSelectorFromString(setterName);
    
    if ((encoding.UTF8String)[0] == @encode(id)[0]) {
        IMP getterImplementation = imp_implementationWithBlock(^id(id self) {
            return objc_getAssociatedObject(self, getter);
        });
        
        objc_AssociationPolicy associationPolicy = 0;
        
        if (memoryManagement == MemoryManagementCopy) {
            associationPolicy = isNonatomic ? OBJC_ASSOCIATION_COPY_NONATOMIC : OBJC_ASSOCIATION_COPY;
        } else {
            associationPolicy = isNonatomic ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_RETAIN;
        }
        
        IMP setterImplementation = imp_implementationWithBlock(^(id self, id object) {
            objc_setAssociatedObject(self, getter, object, associationPolicy);
        });
        
        class_addMethod(klass, getter, getterImplementation, "@@:");
        class_addMethod(klass, setter, setterImplementation, "v@:@");
        
        return;
    }
    
    objc_AssociationPolicy associationPolicy = isNonatomic ? OBJC_ASSOCIATION_RETAIN_NONATOMIC : OBJC_ASSOCIATION_RETAIN;
    
#define CASE(type, selectorpart) if (encoding.UTF8String[0] == @encode(type)[0]) {\
IMP getterImplementation = imp_implementationWithBlock(^type(id self) {\
return [objc_getAssociatedObject(self, getter) selectorpart##Value];\
});\
\
IMP setterImplementation = imp_implementationWithBlock(^(id self, type object) {\
objc_setAssociatedObject(self, getter, @(object), associationPolicy);\
});\
\
class_addMethod(klass, getter, getterImplementation, "@@:");\
class_addMethod(klass, setter, setterImplementation, "v@:@");\
\
return;\
}
    
    CASE(char, char);
    CASE(unsigned char, unsignedChar);
    CASE(short, short);
    CASE(unsigned short, unsignedShort);
    CASE(int, int);
    CASE(unsigned int, unsignedInt);
    CASE(long, long);
    CASE(unsigned long, unsignedLong);
    CASE(long long, longLong);
    CASE(unsigned long long, unsignedLongLong);
    CASE(float, float);
    CASE(double, double);
    CASE(BOOL, bool);
    
#undef CASE
    
    NSCAssert(NO, @"encoding %@ in not supported", encoding);
}

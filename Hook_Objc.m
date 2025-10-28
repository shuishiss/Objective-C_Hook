#import "Hook_Objc.h"
#import <objc/runtime.h>

static Class ms_getMetaclass(Class aClass);

@implementation NSObject (Hook_Objc)

static Class ms_getMetaclass(Class aClass) {
    if (class_isMetaClass(aClass)) {
        return aClass;
    }
    return object_getClass(aClass);
}

+ (BOOL)ms_swizzledResolveInstanceMethod:(SEL)sel {
    return NO;
}

+ (BOOL)ms_exchangeMethod:(Class)targetClass
         originalSelector:(SEL)originalSelector
         swizzledSelector:(SEL)swizzledSelector
{
    Method originalMethod = class_getInstanceMethod(targetClass, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(targetClass, swizzledSelector);

    if (!originalMethod || !swizzledMethod) {
        NSLog(@"[Hook_Objc Error] Swizzling failed. Target: %@, Original: %@, Swizzled: %@",
              NSStringFromClass(targetClass), NSStringFromSelector(originalSelector), NSStringFromSelector(swizzledSelector));
        return NO;
    }

    BOOL didAddMethod = class_addMethod(targetClass,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));

    if (didAddMethod) {
        class_replaceMethod(targetClass,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
    return YES;
}

+ (BOOL)ms_swizzleInstanceMethod:(Class)aClass
                originalSelector:(SEL)originalSelector
                swizzledSelector:(SEL)swizzledSelector
{
    return [self ms_exchangeMethod:aClass
                  originalSelector:originalSelector
                  swizzledSelector:swizzledSelector];
}

+ (BOOL)ms_swizzleClassMethod:(Class)aClass
             originalSelector:(SEL)originalSelector
             swizzledSelector:(SEL)swizzledSelector
{
    Class metaClass = ms_getMetaclass(aClass);
    return [self ms_exchangeMethod:metaClass
                  originalSelector:originalSelector
                  swizzledSelector:swizzledSelector];
}

+ (BOOL)ms_addInstanceMethod:(Class)aClass
                    selector:(SEL)selector
         implementationBlock:(id)implementationBlock
                typeEncoding:(const char *)typeEncoding
{
    IMP imp = imp_implementationWithBlock(implementationBlock);
    
    return class_addMethod(aClass, selector, imp, typeEncoding);
}

+ (BOOL)ms_replaceInstanceMethod:(Class)aClass
                        selector:(SEL)selector
             implementationBlock:(id)implementationBlock
{
    Method method = class_getInstanceMethod(aClass, selector);
    if (!method) {
        NSLog(@"[Hook_Objc Error] Replacement failed. Method %@ not found in class %@", 
              NSStringFromSelector(selector), NSStringFromClass(aClass));
        return NO;
    }
    
    IMP newIMP = imp_implementationWithBlock(implementationBlock);

    class_replaceMethod(aClass, selector, newIMP, method_getTypeEncoding(method));

    return YES;
}

+ (BOOL)ms_hookResolveInstanceMethod:(Class)aClass
                   resolutionBlock:(BOOL (^)(id, SEL))block
{
    Class metaClass = ms_getMetaclass(aClass);

    Method originalResolveMethod = class_getClassMethod(metaClass, @selector(resolveInstanceMethod:));
    if (!originalResolveMethod) {
        NSLog(@"Hook_Objc Error   resolveInstanceMethod: not found on meta class %@", NSStringFromClass(metaClass));
        return NO;
    }
    
    BOOL (^newResolveIMP)(Class, SEL, SEL) = ^BOOL(Class self, SEL _cmd, SEL selector) {
        if (block(self, selector)) {
            return YES;
        }
        
        return [self ms_swizzledResolveInstanceMethod:selector];
    };
    
    IMP newIMP = imp_implementationWithBlock(newResolveIMP);
    class_replaceMethod(metaClass, 
                        @selector(ms_swizzledResolveInstanceMethod:), 
                        newIMP, 
                        method_getTypeEncoding(originalResolveMethod));

    return [self ms_exchangeMethod:metaClass
                  originalSelector:@selector(resolveInstanceMethod:)
                  swizzledSelector:@selector(ms_swizzledResolveInstanceMethod:)];
}

+ (BOOL)ms_hookForwardInvocation:(Class)aClass
             invocationBlock:(void (^)(id, NSInvocation *))block
{
    void (^newForwardIMP)(id, SEL, NSInvocation *) = ^(id self, SEL _cmd, NSInvocation *invocation) {
        block(self, invocation);
    };

    return [self ms_replaceInstanceMethod:aClass
                                selector:@selector(forwardInvocation:)
                  implementationBlock:(id)newForwardIMP];
}

@end

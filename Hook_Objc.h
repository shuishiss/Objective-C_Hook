#import <Foundation/Foundation.h>

@interface NSObject (Hook_Objc)

+ (BOOL)ms_swizzleInstanceMethod:(Class)aClass
                originalSelector:(SEL)originalSelector
                swizzledSelector:(SEL)swizzledSelector;
+ (BOOL)ms_swizzleClassMethod:(Class)aClass
             originalSelector:(SEL)originalSelector
             swizzledSelector:(SEL)swizzledSelector;
+ (BOOL)ms_addInstanceMethod:(Class)aClass
                    selector:(SEL)selector
         implementationBlock:(id)implementationBlock
                typeEncoding:(const char *)typeEncoding;
+ (BOOL)ms_replaceInstanceMethod:(Class)aClass
                        selector:(SEL)selector
             implementationBlock:(id)implementationBlock;
+ (BOOL)ms_hookResolveInstanceMethod:(Class)aClass
                   resolutionBlock:(BOOL (^)(id, SEL))block;
+ (BOOL)ms_hookForwardInvocation:(Class)aClass
                 invocationBlock:(void (^)(id, NSInvocation *))block;

@end


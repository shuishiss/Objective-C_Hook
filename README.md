Hook-Objc-Tools
Objective-C Runtime API 的轻量级封装，用于简化方法交换 (Method Swizzling)、方法添加和消息转发 Hook 操作。



特性 (Features)
• 简洁封装: 对 Objective-C Runtime API 进行了轻量级封装，简化方法交换、方法添加和消息转发机制的 Hook 操作。
• 方法交换 (Swizzling): 提供了实例方法 (ms_swizzleInstanceMethod) 和类方法 (ms_swizzleClassMethod) 的交换接口。
• Block 支持: 支持使用 Block 作为方法实现 (ms_addInstanceMethod, ms_replaceInstanceMethod)。
• 消息转发 Hook: 提供了 Hook +resolveInstanceMethod: 和 -forwardInvocation: 的能力。
• 应用场景: 可用于增加系统 UI 控件的行为，比如注入日志，捕获未识别的选择器防止崩溃等。

如何导入 (Installation)
推荐使用手动导入方式：
将 Hook_Objc.h 和 Hook_Objc.m 文件导入到您的 Xcode 项目中。
在需要使用 Hook 功能的文件或项目的 Bridging Header 中导入：
#import "Hook_Objc.h"

使用方法 (Usage)
所有 Hook 方法都通过 NSObject 的分类 Hook_Objc 提供。
重要安全提示 (Safety Warning)
为了保证线程安全和防止方法交换被多次执行，所有的方法交换 API 调用（ms_swizzle...）都应该使用 dispatch_once 进行包裹。
1. 方法交换 (Method Swizzling)
#import "Hook_Objc.h"

@implementation MyClass (Hook)

+ (void)load {
    // 确保方法交换只执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self ms_swizzleInstanceMethod:[self class]
                      originalSelector:@selector(originalMethod)
                      swizzledSelector:@selector(ms_originalMethod)];
    });
}

// 替换方法：注意在实现中调用原始方法（此时被交换到 ms_originalMethod 上）
- (void)ms_originalMethod {
    // 1. 注入自定义逻辑
    NSLog(@"[Hook] Before calling original method.");
    
    // 2. 调用原始实现
    [self ms_originalMethod];
    
    // 3. 注入自定义逻辑
}

@end
2. 捕获未识别选择器 (Hook resolveInstanceMethod:)
用于防止因调用不存在的实例方法而导致的崩溃：
// 在 App 启动时，对需要保护的类执行
[NSObject ms_hookResolveInstanceMethod:[MyClass class] resolutionBlock:^BOOL(id self, SEL selector) {
    
    // 检查是否是需要处理的特定选择器
    if ([NSStringFromSelector(selector) hasPrefix:@"nonExistent_"]) {
        
        // 动态添加一个假的实现来处理这个方法
        BOOL success = [self ms_addInstanceMethod:[self class] 
                                         selector:selector 
                              implementationBlock:^void(id target) {
                                  NSLog(@"[CrashGuard] Ignored selector: %@", NSStringFromSelector(selector));
                              } 
                                     typeEncoding:"v@:"]; // v:void, @:id, ::SEL
        return success; // 返回YES表示已处理
    }
    
    return NO; // 返回NO，让原始的 resolveInstanceMethod: 继续执行
}];

API 参考 (API Reference)
所有方法都是 NSObject 分类方法，支持传入任意目标 Class。
• ms_swizzleInstanceMethod:originalSelector:swizzledSelector:: 交换目标类的实例方法。
• ms_swizzleClassMethod:originalSelector:swizzledSelector:: 交换目标类的类方法。
• ms_addInstanceMethod:selector:implementationBlock:typeEncoding:: 向目标类动态添加实例方法，使用 Block 作为实现。
• ms_replaceInstanceMethod:selector:implementationBlock:: 替换目标类现有实例方法的实现，使用 Block。
• ms_hookResolveInstanceMethod:resolutionBlock:: Hook +resolveInstanceMethod:，用于在方法动态解析阶段注入逻辑。
• ms_hookForwardInvocation:invocationBlock:: Hook -forwardInvocation:，在消息转发的最后一步执行自定义逻辑。

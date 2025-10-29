# 🛠️ Hook-Objc-Tools

**Objective-C Runtime API 的轻量级封装，用于简化方法交换 (Method Swizzling)、方法添加和消息转发 Hook 操作。**

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS-lightgrey.svg)]()
[![Language](https://img-shields.io/badge/language-Objective--C-orange.svg)]()

---

## ✨ 特性 (Features)

* **简洁封装**: 对复杂的 Objective-C Runtime API 进行了轻量级封装，旨在简化方法交换、方法添加和消息转发机制的 Hook 操作。
* **方法交换 (Swizzling)**: 提供了实例方法和类方法的 Method Swizzling 接口。
* **Block 支持**: 支持使用 Block 作为方法实现，提高开发效率。
* **消息转发 Hook**: 提供 Hook `+resolveInstanceMethod:` 和 `-forwardInvocation:` 的能力，已确保 `resolveInstanceMethod:` Hook 的调用链安全。
* **应用场景**: 可用于增加系统 UI 控件的行为，比如注入日志，捕获未识别的选择器防止崩溃等。

## 📦 如何导入 (Installation)

推荐使用手动导入方式：

1.  将 `Hook_Objc.h` 和 `Hook_Objc.m` 文件导入到您的 Xcode 项目中。
2.  在需要使用 Hook 功能的文件中导入：
    ```objective-c
    #import "Hook_Objc.h"
    ```

## 🚀 使用方法 (Usage)

所有 Hook 方法都通过 `NSObject` 的分类 **`Hook_Objc`** 提供。

### ⚠️ **重要安全提示 (Safety Warning)**

为了保证线程安全和防止方法交换被多次执行，**所有的方法交换 API 调用（`ms_swizzle...`）都应该使用 `dispatch_once` 进行包裹**。

#### 1. 方法交换 (Method Swizzling)

```objective-c
#import "Hook_Objc.h"

@implementation MyClass (Hook)

// 推荐在 +load 方法中进行 Swizzling
+ (void)load {
    // 使用 dispatch_once 确保单次执行
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self ms_swizzleInstanceMethod:[self class]
                      originalSelector:@selector(originalMethod)
                      swizzledSelector:@selector(ms_originalMethod)];
    });
}

// 替换方法：注意在实现中调用被 Hook 的原始方法（此时被交换到 ms_originalMethod 上）
- (void)ms_originalMethod {
    // 注入自定义逻辑
    NSLog(@"[Hook] Before calling original method.");
    
    // 调用原始实现
    [self ms_originalMethod];
    
    // 注入自定义逻辑
}

@end
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

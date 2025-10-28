# Objective-C Hook 运行时封装工具 (Objective-C Runtime Hooking Engine)

##  项目简介

本工具是对 Objective-C Runtime API 的轻量级封装，旨在简化方法交换（Swizzling）、方法添加和消息转发机制的 Hook 操作。

**核心优势与应用场景:**

* **轻量易用:** 封装了复杂的 Runtime API，提供简单的类方法调用。
* **功能强大:** 可用于增加系统 UI 控件的行为，注入日志，以及捕获未识别的选择器（`unrecognized selector`）以防止 App 崩溃。

---

## 核心 API (NSObject+Hook_Objc)

所有 Hook 功能都通过 `NSObject (Hook_Objc)` 分类的类方法提供，使用 `ms_` 前缀：

* **方法交换（实例方法）：** `+ms_swizzleInstanceMethod:(Class)aClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector`
* **方法交换（类方法）：** `+ms_swizzleClassMethod:(Class)aClass originalSelector:(SEL)originalSelector swizzledSelector:(SEL)swizzledSelector`
* **替换方法实现：** `+ms_replaceInstanceMethod:(Class)aClass selector:(SEL)selector implementationBlock:(id)implementationBlock` (使用 Block 替换现有实例方法的实现)
* **添加新方法：** `+ms_addInstanceMethod:(Class)aClass selector:(SEL)selector implementationBlock:(id)implementationBlock typeEncoding:(const char *)typeEncoding`
* **Hook 消息转发：** `+ms_hookForwardInvocation:(Class)aClass invocationBlock:(void (^)(id, NSInvocation *))block`
* **Hook 动态解析：** `+ms_hookResolveInstanceMethod:(Class)aClass resolutionBlock:(BOOL (^)(id, SEL))block`

---

##  使用指南 (直接导入源文件)

最简单、最快速的集成方式是直接将源文件加入您的项目编译列表。

### 1. 文件准备

将以下两个核心文件复制到您的项目中：
* `Hook_Objc.h`
* `Hook_Objc.m`

### 2. 编写 Hook 逻辑

在您的 Hook 逻辑文件（例如 `MyTweak.m`）中，导入 `Hook_Objc.h` 并编写您的 `+load` 方法。

** 关键提示:** 必须使用 `dispatch_once` 包裹 Hook API 调用，以确保 Hooking 过程只执行一次，防止错误。

**示例代码（使用 Block 替换方法）：**

```objective-c
#import "Hook_Objc.h" 
#import "TargetClass.h" // 替换为您的目标类

@implementation TargetClass (Hooking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class target = [TargetClass class];
        
        // 示例：替换一个名为 'calculateValue' 的实例方法
        [NSObject ms_replaceInstanceMethod:target
                                 selector:@selector(calculateValue)
                      implementationBlock:^NSInteger(id self) {
            
            NSLog(@"[MyHook] 方法已被替换，返回自定义值 42。");
            return 42; 
        }];
    });
}
@end

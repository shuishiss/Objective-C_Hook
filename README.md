# Hook\_Objc -  Objective-C  Hooking Tools

一个基于 `NSObject` 分类的轻量级 Objective-C 运行时扩展工具集，它封装了复杂的 Runtime API，提供了安全、便捷的方式来实现**方法交换 (Swizzling)**、**动态方法添加/替换**以及对**消息机制**的深度 Hook。

##  特性

本项目主要用于以下目的：

1.  **增强/修改系统固件**：通过 Swizzling 框架类的方法，实现全局行为修改（如页面统计、事件处理）。
2.  **日志记录/调试**：快速 Hook 方法，打印输入参数和调用时机，无需修改原代码。
3.  **防止崩溃**：通过 Hook 动态方法解析和消息转发机制，实现未识别选择器 (Unrecognized Selector) 的容错处理。

| 方法签名 | 功能描述 |
| :--- | :--- |
| `+ms_swizzleInstanceMethod:originalSelector:swizzledSelector:` | 交换给定类的两个**实例方法**的实现。 |
| `+ms_swizzleClassMethod:originalSelector:swizzledSelector:` | 交换给定类的两个**类方法**的实现。 |
| `+ms_addInstanceMethod:selector:implementationBlock:typeEncoding:` | 为类**添加**一个新的**实例方法**（使用 Block 作为实现）。 |
| `+ms_replaceInstanceMethod:selector:implementationBlock:` | 用新的 Block 实现**替换**现有**实例方法**的实现。 |
| `+ms_hookResolveInstanceMethod:resolutionBlock:` | **钩住**类的 `+resolveInstanceMethod:`，通过 Block 提供自定义的**动态方法解析**逻辑。 |
| `+ms_hookForwardInvocation:invocationBlock:` | **钩住**实例方法的 `-forwardInvocation:`，通过 Block 提供自定义的**消息转发/处理**逻辑。 |

##  如何使用

### 1. 导入项目

将 `Hook_Objc.h` 和 `Hook_Objc.m` 文件导入到您的项目中。

### 2. 使用规范（核心）

**必须**使用 `dispatch_once` 对 Hook 操作进行包装，确保运行时修改只执行一次，**推荐在类的 `+load` 方法中执行**。

**示例：实例方法交换 (Method Swizzling)**

```objc
#import "Hook_Objc.h"
#import <UIKit/UIKit.h>

@implementation UIViewController (Hook)

// 在 +load 中执行，保证在应用启动时安全地执行一次
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换 UIViewController 的 viewWillAppear: 方法
        [self ms_swizzleInstanceMethod:[self class] 
                       originalSelector:@selector(viewWillAppear:) 
                       swizzledSelector:@selector(ms_viewWillAppear:)];
    });
}

// 交换后的实现方法
- (void)ms_viewWillAppear:(BOOL)animated {
    // 1. 在这里添加自定义逻辑 (例如：页面统计)
    NSLog(@"[Hook] %@ 将要显示.", NSStringFromClass([self class]));

    // 2. 调用原始实现（**关键步骤**：调用 ms_viewWillAppear: 实际上调用的是被交换前的原始实现）
    [self ms_viewWillAppear:animated]; 
}

@end

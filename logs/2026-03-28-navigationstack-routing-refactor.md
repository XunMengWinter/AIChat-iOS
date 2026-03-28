# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-navigationstack-routing-refactor.md`

## 本次修改了哪些文件
- `AIChat-iOS/ContentView.swift`
- `AIChat-iOS/Stores/AppSessionStore.swift`
- `AIChat-iOS/Views/HomeView.swift`
- `AIChat-iOS/Views/SettingsView.swift`
- `AIChat-iOS/Views/ChatView.swift`

## 每个文件的作用
- `AIChat-iOS/ContentView.swift`
  负责 App 根视图组织，承载根流程页面与统一的 `NavigationStack` 路由出口。
- `AIChat-iOS/Stores/AppSessionStore.swift`
  负责全局会话状态、角色数据、登录状态，以及根流程状态和导航路径的维护。
- `AIChat-iOS/Views/HomeView.swift`
  负责首页展示与主要入口，包括推荐角色、角色列表、最近聊天和设置入口。
- `AIChat-iOS/Views/SettingsView.swift`
  负责设置页展示账号信息与退出登录操作。
- `AIChat-iOS/Views/ChatView.swift`
  负责聊天页展示、历史消息加载、输入发送与会话管理。
- `logs/2026-03-28-navigationstack-routing-refactor.md`
  记录本次路由重构的改动内容、影响范围与验证结果。

## 本次完成了哪些功能
- 将原先基于 `sessionStore.screen` 的整页切换改为“根流程状态 + `NavigationStack` 路由路径”的结构：
  - 根流程只保留 `onboarding / login / home`
  - 栈内页面统一收敛到 `settings / chat`
- 在 `ContentView` 中建立统一 `NavigationStack(path:)`，并通过 `navigationDestination(for:)` 负责设置页和聊天页跳转。
- 在 `AppSessionStore` 中新增导航路径状态与写回处理：
  - 支持根据系统导航路径变化同步当前选中角色
  - 保留根流程切换时自动清空路径，避免旧页面残留在栈中
- 将首页主要跳转入口改为系统导航方式：
  - 设置按钮改为 `NavigationLink(value:)`
  - 推荐卡片“立即聊天”改为 `NavigationLink(value:)`
  - 所有角色卡片改为 `NavigationLink(value:)`
  - 最近聊天列表改为 `NavigationLink(value:)`
  - “继续聊天”快捷入口改为 `NavigationLink(value:)`
- 将聊天页和设置页返回改为 `dismiss()`，不再直接手动切回首页。

## 当前仍未完成的内容
- `onboarding -> login -> home` 这条根流程仍然是根视图切换，不是栈内 push，这属于流程切面而不是层级页面导航。
- 目前还没有为导航状态单独补自动化测试，主要依赖编译验证和后续手动走查。

## 运行说明或注意事项
- 已使用以下命令完成 iPhone 17 模拟器目标编译验证：
  - `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build`
- 编译结果为 `BUILD SUCCEEDED`。
- 编译输出中保留一条非阻塞 warning：
  - `Metadata extraction skipped. No AppIntents.framework dependency found.`
- 已清理本次任务生成的项目内临时构建目录 `.derivedData`。

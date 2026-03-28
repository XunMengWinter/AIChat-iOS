# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-chatview-chatviewmodel-fixes.md`

## 本次修改了哪些文件
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
- `AIChat-iOS/Views/ChatView.swift`

## 每个文件的作用
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
  负责聊天页消息列表、历史加载、发送流程、清空会话、图片草稿与错误状态管理。
- `AIChat-iOS/Views/ChatView.swift`
  负责聊天页整体界面，包括顶部栏、消息列表、快捷话题、图片选择、输入框与发送按钮。
- `logs/2026-03-28-chatview-chatviewmodel-fixes.md`
  记录本次对 `ChatView` 与 `ChatViewModel` 的优化、修复点与验证结果。

## 本次完成了哪些功能
- 修复历史加载与本地会话状态的竞态问题：
  - 角色切换后，旧请求结果不会再回写到当前会话
  - 历史加载过程中如果先发送消息或先清空聊天，晚到的历史结果不会覆盖本地最新状态
- 修复异步任务取消时的错误提示问题：
  - 历史加载或清空流程在任务被取消时不再误显示错误 Banner
- 优化发送失败时的状态处理：
  - 如果回复尚未真正开始返回，失败后会回滚占位消息并尽量恢复原草稿
  - 如果已经收到部分回复内容，则保留已有内容并展示错误信息，避免直接丢失上下文
- 优化历史消息展示：
  - 优先过滤 `isPartial` 的半截历史消息，避免把流式中间态当成正式历史
  - 过滤空白且无图片的无效消息
- 优化 `ChatView` 交互边界：
  - 发送中或清空中禁用快捷话题与清空入口，减少冲突操作
  - 清空过程中禁用输入框与图片选择
  - 消息列表支持交互式下拉收起键盘

## 当前仍未完成的内容
- 项目当前没有单独的自动化测试 target，本次未补充单元测试。
- 仍需在 iPhone 17 模拟器里手动走一遍以下场景：
  - 进入聊天页后立刻切换角色
  - 历史加载未完成时先发送消息
  - 发送失败与清空聊天的边界交互

## 运行说明或注意事项
- 已使用以下命令完成编译验证：
  - `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build`
- 编译结果为 `BUILD SUCCEEDED`。
- 编译输出中仍有一条 `Metadata extraction skipped. No AppIntents.framework dependency found.` warning，为非阻塞提示，不影响本次聊天页修改。
- 已清理本次任务生成的项目内临时构建目录 `.derivedData`。

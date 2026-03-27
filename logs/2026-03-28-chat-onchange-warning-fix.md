# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-chat-onchange-warning-fix.md`

## 本次修改了哪些文件
- `AIChat-iOS/Views/ChatView.swift`

## 每个文件的作用
- `AIChat-iOS/Views/ChatView.swift`
  负责聊天页消息列表展示、自动滚动、输入区和图片选择入口。
- `logs/2026-03-28-chat-onchange-warning-fix.md`
  记录本次修复聊天页 `onChange(of: String)` warning 的改动内容。

## 本次完成了哪些功能
- 移除了聊天页里对 `viewModel.messages.last?.content` 的直接 `onChange` 监听。
- 改为使用 `Combine` 对消息变化做：
  - 消息数量变化时立即滚动到底部
  - 最后一条消息内容变化时先去重，再做 `80ms` 轻微节流后无动画滚动
- 修复了流式输出期间容易出现的日志警告：
  - `onChange(of: String) action tried to update multiple times per frame.`

## 当前仍未完成的内容
- 尚未验证这个 warning 在所有极端高频流式输出场景下都完全消失。
- 如果后续仍有滚动性能问题，需要再看是否要把自动滚动策略进一步下沉到 ViewModel 节流。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次修复结果。

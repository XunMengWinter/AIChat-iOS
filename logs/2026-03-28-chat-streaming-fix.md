# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-chat-streaming-fix.md`

## 本次修改了哪些文件
- `AIChat-iOS/Services/APIClient.swift`
- `AIChat-iOS/Services/ChatService.swift`
- `AIChat-iOS/ViewModels/ChatViewModel.swift`

## 每个文件的作用
- `AIChat-iOS/Services/APIClient.swift`
  统一构建请求头与处理普通请求、SSE 流式请求。
- `AIChat-iOS/Services/ChatService.swift`
  封装聊天相关接口，包括历史、清空和流式聊天。
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
  控制聊天页发送流程、消息列表状态和流式消息渲染。
- `logs/2026-03-28-chat-streaming-fix.md`
  记录本次“移除全量历史重拉并强化流式请求头”的调整内容。

## 本次完成了哪些功能
- 移除了聊天发送完成后立刻全量重拉历史的逻辑。
- 现在流式响应结束后，前端只结束当前助手消息的 streaming 状态，不再马上用历史接口覆盖本地流式内容。
- 为 `/chat/stream` 请求单独设置 `Accept: text/event-stream`，避免继续沿用普通 JSON 请求头。
- 保留现有的 SSE 解析逻辑和增量追加逻辑，不改消息列表结构。

## 当前仍未完成的内容
- 尚未从终端直接抓取线上 SSE 响应做网络层验证。
- 如果后端本身就是“延迟几秒后集中分块返回”，即使前端修正后仍可能表现为晚开始；那时需要继续看服务端分块策略。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次流式逻辑调整。

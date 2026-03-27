# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-stream-request-alignment.md`

## 本次修改了哪些文件
- `AIChat-iOS/Services/APIClient.swift`
- `AIChat-iOS/Services/ChatService.swift`

## 每个文件的作用
- `AIChat-iOS/Services/APIClient.swift`
  负责统一构建接口请求、处理普通响应与 SSE 流式响应，并输出请求/响应日志。
- `AIChat-iOS/Services/ChatService.swift`
  负责封装聊天接口，包括 `/chat/stream` 请求体与请求头的构造。
- `logs/2026-03-28-stream-request-alignment.md`
  记录本次把 iOS `/chat/stream` 请求向测试页对齐的改动内容。

## 本次完成了哪些功能
- 为 iOS 的 `/chat/stream` 请求补上 `temperature: 0.8`，与测试页保持一致。
- 调整 `APIClient.makeRequest`，允许请求不显式设置 `Accept`。
- `/chat/stream` 现在不再显式带 `Accept` 请求头，改为只保留测试页风格的基础头信息。
- 在 SSE 日志里新增首个 delta 的显式时间点日志：
  - 距离请求发出的耗时
  - 距离 `STREAM OPEN` 的耗时

## 当前仍未完成的内容
- 尚未基于这次新对齐后的请求，再做一轮与你的测试页逐条对比的真实联调验证。
- 如果对齐后首包仍慢，问题就更偏向服务端/网关分块策略，而不是 iOS 请求格式差异。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 新日志会在控制台中新增 `FIRST DELTA` 行，便于直接观察：
  - `after_request`
  - `after_stream_open`
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次改动。

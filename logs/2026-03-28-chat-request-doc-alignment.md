# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-chat-request-doc-alignment.md`

## 本次修改了哪些文件
- `AIChat-iOS/Services/APIClient.swift`
- `AIChat-iOS/Services/ChatService.swift`

## 每个文件的作用
- `AIChat-iOS/Services/APIClient.swift`
  统一负责普通 JSON 请求和 SSE 流式请求的构造、超时、缓存策略和日志输出。
- `AIChat-iOS/Services/ChatService.swift`
  负责封装聊天相关接口，尤其是 `/chat/stream` 的请求体与请求头。
- `logs/2026-03-28-chat-request-doc-alignment.md`
  记录本次将聊天页请求从“测试页对齐策略”收回到“API 文档 + 客户端最佳实践”的调整内容。

## 本次完成了哪些功能
- 移除了 `/chat/stream` 请求里固定写死的 `temperature=0.8`。
- 现在 `/chat/stream` 默认只传文档要求和业务实际需要的字段：
  - `role_code`
  - `message`（有值时）
  - `image_base64`（有图时）
  - `image_mime_type`（有图时）
- 恢复 SSE 请求的正式请求头：
  - `Accept: text/event-stream`
- 为流式请求单独设置了更合理的网络配置：
  - 更长的超时时间
  - 忽略本地与远端缓存
- 保留现有的流式时序日志能力：
  - `STREAM REQUEST`
  - `STREAM OPEN`
  - `FIRST DELTA`
  - `stream completed`

## 当前仍未完成的内容
- 尚未重新基于这版“文档对齐”客户端，再做一次同句对比测试。
- 若这版仍然出现 `FIRST DELTA after_stream_open` 明显偏大，后续结论仍会继续指向服务端/上游首包延迟，而不是客户端请求构造。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次改动。

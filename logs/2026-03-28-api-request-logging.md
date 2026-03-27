# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-api-request-logging.md`

## 本次修改了哪些文件
- `AIChat-iOS/Services/APIClient.swift`

## 每个文件的作用
- `AIChat-iOS/Services/APIClient.swift`
  统一负责所有接口请求的构建、普通响应处理、SSE 流式响应处理，以及现在新增的接口日志输出。
- `logs/2026-03-28-api-request-logging.md`
  记录本次“为所有接口请求打日志”的改动内容与验证结果。

## 本次完成了哪些功能
- 为所有通过 `APIClient` 发出的接口请求增加统一日志，包括：
  - 请求开始
  - 响应返回
  - 解码成功/失败
  - 错误返回
  - SSE 连接建立
  - SSE payload 摘要
  - SSE delta 摘要
  - SSE 完成
- 日志内容包含：
  - 请求 ID
  - 时间戳
  - 请求方法
  - 请求 URL
  - 请求头摘要
  - 请求体摘要
  - 响应状态码
  - 响应耗时
  - 响应体摘要
- 对敏感字段做了日志脱敏处理：
  - `Authorization`
  - `access_token`
  - `verify_code`
  - `phone_number`
  - `image_base64`
- 对大字段和长文本做了截断，避免控制台被完整 Base64 或超长内容刷屏。

## 当前仍未完成的内容
- 当前日志是控制台日志，没有额外写入本地文件。
- 远程图片加载（例如 Nuke 拉取头像和背景图）不走 `APIClient`，因此不会出现在这套接口日志里。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 日志会直接输出到 Xcode 控制台，前缀格式为 `[API] 时间戳 [请求ID] ...`。
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次接口日志功能。

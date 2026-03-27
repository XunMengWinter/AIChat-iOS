# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-chat-image-session-removal.md`

## 本次修改了哪些文件
- `AIChat-iOS/ViewModels/ChatViewModel.swift`

## 每个文件的作用
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
  负责聊天页的消息列表、图片草稿、发送流程、历史刷新与清空聊天逻辑。
- `logs/2026-03-28-chat-image-session-removal.md`
  记录本次“移除聊天图片会话内保留逻辑”的改动与验证结果。

## 本次完成了哪些功能
- 移除了聊天图片在当前会话内匹配回历史消息的缓存逻辑。
- 现在图片只会在用户刚发送时作为本地预览显示在乐观消息中。
- 一旦流式响应结束并重新拉取历史，带图消息会直接退化为后端 `has_image` 对应的图片占位，不再尝试把本地缩略图保存在会话里。
- 清空聊天时也会一并清除当前输入区未发送的图片草稿。

## 当前仍未完成的内容
- 尚未对“看起来不像流式返回”的现象做线上抓包级别验证。
- 目前从代码层判断，图片改动没有把聊天从 `APIClient.stream` 改成普通请求；若仍然不是流式观感，需要进一步检查后端分块粒度或前端是否被历史刷新掩盖。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次逻辑调整。

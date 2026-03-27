# 本次改动日志

## 本次新增了哪些文件
- `AIChat-iOS/Models/ChatImageAttachment.swift`
- `AIChat-iOS/Utilities/ChatImageProcessor.swift`
- `logs/2026-03-27-chat-image-upload.md`

## 本次修改了哪些文件
- `AIChat-iOS/Models/APIError.swift`
- `AIChat-iOS/Services/ChatService.swift`
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
- `AIChat-iOS/Views/ChatView.swift`

## 每个文件的作用
- `AIChat-iOS/Models/ChatImageAttachment.swift`
  定义聊天图片草稿结构，保存预览图、上传数据、Base64、MIME 类型和压缩后尺寸。
- `AIChat-iOS/Utilities/ChatImageProcessor.swift`
  负责读取用户选中的图片、按最长边 `1440px` 压缩、输出 JPEG 数据与预览图。
- `AIChat-iOS/Models/APIError.swift`
  新增图片处理失败错误类型，统一通过现有错误提示栏展示。
- `AIChat-iOS/Services/ChatService.swift`
  扩展聊天流式请求体，支持同时发送 `message`、`image_base64` 和 `image_mime_type`。
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
  增加图片草稿状态、发送中图片消息、本地缩略图匹配缓存，以及图片清理逻辑。
- `AIChat-iOS/Views/ChatView.swift`
  在输入区接入 `PhotosPicker`，增加待发送缩略图卡片、图片移除按钮、图片消息气泡与图片占位展示。
- `logs/2026-03-27-chat-image-upload.md`
  记录本次聊天页图片发送功能的完整改动内容。

## 本次完成了哪些功能
- 为聊天输入区新增单张图片选择能力，仅支持系统相册，不接相机。
- 选图后会先在输入区显示待发送缩略图，并支持移除。
- 图片发送前会压缩为 JPEG，最长边限制为 `1440px`，短边按比例缩放，小图不放大。
- 聊天发送链路现已支持：
  - 纯文本
  - 纯图片
  - 文本 + 图片
- 当前会话内，用户刚发送的图片消息会显示真实本地缩略图。
- 流式响应结束并重新拉历史后，会优先把本地缩略图重新匹配到本次会话里的图片消息。
- 重新进入会话或历史里没有本地可匹配缩略图时，图片消息退化为通用图片占位。
- 清空聊天时会同步清掉当前会话里的图片草稿和本地缩略图缓存。

## 当前仍未完成的内容
- 尚未支持拍照入口。
- 尚未支持多图发送。
- 后端历史接口不返回图片本体，因此跨会话不会恢复真实缩略图，只显示图片占位。
- 未完成手工图片联调验证；目前已验证编译通过并能启动 App，但尚未在模拟器里完整走通真实选图上传流程。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 已将 App 安装并拉起到 `iPhone 17` 模拟器，确认新引入的图片选择依赖不会影响启动。
- 编译输出中的 `AppIntents.framework` metadata warning 为 Xcode 非阻塞警告，不影响本次图片发送功能。

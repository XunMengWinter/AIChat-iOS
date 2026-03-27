# 本次改动日志

## 本次新增了哪些文件
- `AIChat-iOS/Models/APIError.swift`
- `AIChat-iOS/Models/User.swift`
- `AIChat-iOS/Models/Role.swift`
- `AIChat-iOS/Models/HistoryMessage.swift`
- `AIChat-iOS/Models/LoginSession.swift`
- `AIChat-iOS/Models/RecentChatSummary.swift`
- `AIChat-iOS/Models/StreamChunk.swift`
- `AIChat-iOS/Models/APIResponses.swift`
- `AIChat-iOS/Utilities/APIJSONDecoder.swift`
- `AIChat-iOS/Utilities/AppDateFormatter.swift`
- `AIChat-iOS/Utilities/AppTheme.swift`
- `AIChat-iOS/Services/APIClient.swift`
- `AIChat-iOS/Services/LoginService.swift`
- `AIChat-iOS/Services/ChatService.swift`
- `AIChat-iOS/Stores/AppStorage.swift`
- `AIChat-iOS/Stores/AppSessionStore.swift`
- `AIChat-iOS/ViewModels/LoginViewModel.swift`
- `AIChat-iOS/ViewModels/HomeViewModel.swift`
- `AIChat-iOS/ViewModels/ChatViewModel.swift`
- `AIChat-iOS/Views/Components/RemoteImageView.swift`
- `AIChat-iOS/Views/OnboardingView.swift`
- `AIChat-iOS/Views/LoginView.swift`
- `AIChat-iOS/Views/HomeView.swift`
- `AIChat-iOS/Views/ChatView.swift`
- `AIChat-iOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

## 本次修改了哪些文件
- `AIChat-iOS.xcodeproj/project.pbxproj`
- `AIChat-iOS/AIChat_iOSApp.swift`
- `AIChat-iOS/ContentView.swift`

## 每个文件的作用
- `Models/*`：定义用户、角色、历史消息、登录会话、最近聊天摘要、SSE chunk 和接口响应模型。
- `Utilities/APIJSONDecoder.swift`：统一接口解码策略，处理蛇形字段和 `created_at` 日期格式。
- `Utilities/AppDateFormatter.swift`：格式化最近聊天时间与聊天消息时间。
- `Utilities/AppTheme.swift`：集中定义页面主色、渐变和通用颜色。
- `Services/APIClient.swift`：统一构建请求、处理 JSON 响应、处理标准错误结构、解析 SSE 流。
- `Services/LoginService.swift`：封装验证码发送与登录接口。
- `Services/ChatService.swift`：封装角色列表、聊天历史、流式聊天、清空聊天接口。
- `Stores/AppStorage.swift`：基于 `UserDefaults` 持久化登录态、已选角色和选角完成状态。
- `Stores/AppSessionStore.swift`：作为全局状态入口，驱动引导、登录、首页、聊天页切换。
- `ViewModels/*`：分别负责登录表单倒计时、首页最近聊天聚合、聊天页历史加载/发送/清空。
- `Views/Components/RemoteImageView.swift`：通过 `NukeUI` 统一加载远程头像和背景图。
- `Views/OnboardingView.swift`：实现角色选取引导页。
- `Views/LoginView.swift`：实现验证码登录页。
- `Views/HomeView.swift`：实现首页推荐角色、所有角色和最近聊天聚合列表。
- `Views/ChatView.swift`：实现聊天页、消息流展示、快捷话题与清空聊天。
- `project.pbxproj` 与 `Package.resolved`：引入 `Nuke` 和 `NukeUI` 包依赖。
- `AIChat_iOSApp.swift` 与 `ContentView.swift`：接入 `AppSessionStore`，把空白入口替换成真实 App 根流程。

## 本次完成了哪些功能
- 按 Figma 主流程实现了引导选角、验证码登录、首页、聊天页四个核心页面。
- 接入真实后端 API，包括：
  - `GET /chat/roles`
  - `POST /send_code`
  - `POST /login`
  - `GET /chat/history`
  - `POST /chat/stream`
  - `POST /chat/clear`
- 实现了基于 `UserDefaults` 的登录态、选角状态和已选角色持久化。
- 实现了 SSE 流式聊天增量渲染，并在流结束后重新拉取历史保证会话一致。
- 实现了首页“最近聊天”真实聚合逻辑：遍历角色历史，提取最新消息后按时间倒序展示。
- 实现了 `401 Unauthorized` 统一回登录页处理。
- 引入并使用 `Nuke/NukeUI` 加载远程头像和背景图。

## 当前仍未完成的内容
- 未实现图片发送与图片消息展示。
- 未新增设计稿外的设置页、协议详情页、聊天记录独立页。
- 未做 Keychain、离线缓存、埋点、未读数等扩展能力。
- 由于当前终端网络环境限制，未在命令行中直接完成真实接口返回值抓取验证，联调依赖模拟器内实际运行。

## 运行说明或注意事项
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 已将 App 安装并拉起到 `iPhone 17` 模拟器，确认应用可启动。
- 测试账号按照 API 文档使用：手机号 `10086`，验证码 `1234`，国家码 `86`。

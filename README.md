# AI 陪伴聊天 App

一个基于 SwiftUI 实现的 iOS AI 陪伴聊天客户端项目。

项目以 Figma 设计稿为视觉参考，以后端 API 文档为联调依据，当前已实现从角色引导、验证码登录到流式聊天的完整主流程，适合作为 SwiftUI + SSE 聊天类 App 的实践样例。

AIChat-iOS is an iOS client built with SwiftUI for an AI companion chat experience.  
It follows a Figma design and integrates with a real backend API, covering onboarding, SMS login, role-based chat, SSE streaming replies, and image-assisted messaging.

## 目录

- [项目简介](#项目简介)
- [功能特性](#功能特性)
- [预览](#预览)
- [技术栈](#技术栈)
- [项目结构](#项目结构)
- [运行方式](#运行方式)
- [接口与联调](#接口与联调)
- [当前实现范围](#当前实现范围)
- [已知限制 / TODO](#已知限制--todo)
- [致谢](#致谢)
- [Contributing](#contributing)

## 项目简介

本项目目标是实现一款可运行的 AI 陪伴聊天 App，并尽量贴近设计稿完成真实页面与交互流程。

- 客户端基于 SwiftUI 开发，支持 iOS 17 及以上。
- 项目当前仓库仅包含 iOS 客户端实现，不包含后端服务代码。
- UI 视觉与页面层级参考 Figma 设计稿。
- 接口行为、请求参数与联调方式参考后端 API 文档。

## 功能特性

当前仓库中已经实现、且可以从代码与日志中验证的能力包括：

- 角色引导页：支持浏览和选择 AI 角色，作为进入主流程前的选角步骤。
- 验证码登录：支持手机号 + 验证码登录流程。
- 首页角色展示：支持推荐角色、全部角色与最近聊天聚合列表。
- 聊天主流程：支持进入指定角色会话、展示历史消息、继续对话。
- 流式回复：聊天回复基于 SSE 流式增量渲染，网络层当前使用 Alamofire。
- 图片发送：支持单张图片、纯图片、文本 + 图片发送。
- 清空聊天：支持清空当前角色会话历史。
- 设置页：支持查看当前账号信息、当前选中角色与退出登录。
- 登录态持久化：本地持久化登录会话、已选角色和选角完成状态。

## 预览

截图 / GIF 待补充。

当前仓库暂未包含演示图片资源，后续可在该部分补充：

- Onboarding 角色选择页
- 首页角色列表与最近聊天
- 聊天页流式回复演示
- 图片发送与设置页

## 技术栈

- SwiftUI
- Alamofire 5.11.1
- Nuke / NukeUI 12.9.0
- iOS 17+
- Xcode
- iPhone 17 Simulator
- Swift Package Manager

## 项目结构

```text
.
├── AIChat-iOS
│   ├── Models        # 接口响应、聊天消息、角色、会话等数据模型
│   ├── Stores        # 全局会话状态与本地持久化
│   ├── Services      # APIClient、登录接口、聊天接口封装
│   ├── Utilities     # 主题、日期格式、图片处理、统一解码等工具
│   ├── ViewModels    # 登录、首页、聊天等页面状态与业务逻辑
│   └── Views         # Onboarding、Login、Home、Chat、Settings 等页面
├── AIChat-iOS.xcodeproj
└── logs              # 每次任务的改动日志
```

## 运行方式

### 前置要求

- macOS + Xcode
- iOS 17 及以上模拟器运行环境
- 建议直接使用 iPhone 17 模拟器进行验证

### 启动步骤

1. 打开 [AIChat-iOS.xcodeproj](./AIChat-iOS.xcodeproj)。
2. 等待 Swift Package Manager 自动解析并拉取依赖。
3. 选择 `iPhone 17` 模拟器。
4. 使用 Debug 配置执行 Build & Run。

### 依赖管理

项目依赖通过 Swift Package Manager 管理，当前已接入：

- [Alamofire](https://github.com/alamofire/alamofire)
- [Nuke](https://github.com/kean/Nuke)

## 接口与联调

### 后端 API 文档

[https://xunmengwinter.github.io/ai-chat-api-wiki/](https://xunmengwinter.github.io/ai-chat-api-wiki/)

### Figma 设计稿

[https://www.figma.com/make/iqRAARQKZrkTia08nrxN3V/AI%E9%99%AA%E4%BC%B4%E8%81%8A%E5%A4%A9App%E5%BC%95%E5%AF%BC%E9%A1%B5](https://www.figma.com/make/iqRAARQKZrkTia08nrxN3V/AI%E9%99%AA%E4%BC%B4%E8%81%8A%E5%A4%A9App%E5%BC%95%E5%AF%BC%E9%A1%B5)

### 测试账号

以下信息用于本地体验当前客户端流程：

- 手机号：`10086`
- 验证码：`1234`
- 国家码：`86`

## 当前实现范围

### 已接入接口

- `GET /chat/roles`
- `POST /send_code`
- `POST /login`
- `GET /chat/history`
- `POST /chat/stream`
- `POST /chat/clear`

### 聊天与图片发送现状

- 支持基于 SSE 的流式回复。
- 支持单张图片发送。
- 支持纯文本、纯图片、文本 + 图片三种发送方式。
- 当前会话内会尽量显示本地图片缩略图。
- 当历史回放无法恢复真实图片缩略图时，消息会回退为通用图片占位。

## 已知限制 / TODO

- 暂不支持拍照入口。
- 暂不支持多图发送。
- 暂无单元测试。
- 暂无 token 自动刷新机制。
- 暂无统一重试策略。
- 暂无离线缓存能力。
- 预览截图 / GIF 待补充。

## 致谢

感谢以下项目与资料为本仓库提供支持或参考：

- [Alamofire](https://github.com/alamofire/alamofire)
- [Nuke](https://github.com/kean/Nuke)
- [Figma 设计稿](https://www.figma.com/make/iqRAARQKZrkTia08nrxN3V/AI%E9%99%AA%E4%BC%B4%E8%81%8A%E5%A4%A9App%E5%BC%95%E5%AF%BC%E9%A1%B5)
- [后端 API 文档](https://xunmengwinter.github.io/ai-chat-api-wiki/)

## Contributing

欢迎通过 Issue 或 Pull Request 提出问题、建议和改进方案。

如果你准备贡献代码，建议先阅读项目约束说明，并尽量保持实现简单、清晰、可维护。

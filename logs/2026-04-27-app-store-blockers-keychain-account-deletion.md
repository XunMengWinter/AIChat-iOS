# 2026-04-27 上架阻塞项补齐

## 本次新增文件

- `AIChat-iOS/Stores/KeychainStore.swift`
  - 新增轻量 Keychain 读写封装，用于保存登录会话。
- `AIChat-iOS/ViewModels/SettingsViewModel.swift`
  - 新增设置页账号注销状态管理和接口调用逻辑。
- `AIChat-iOS/Utilities/AppLegalLinks.swift`
  - 新增用户协议和隐私政策链接集中配置。
- `AIChat-iOS/Views/Components/SafariView.swift`
  - 新增 `SFSafariViewController` SwiftUI 包装，用于 App 内打开协议页面。
- `docs/privacy-policy.md`
  - 新增可复制到 Notion 的隐私政策草稿。
- `docs/user-agreement.md`
  - 新增可复制到 Notion 的用户协议草稿。
- `logs/2026-04-27-app-store-blockers-keychain-account-deletion.md`
  - 记录本次上架阻塞项补齐内容。

## 本次修改文件

- `AIChat-iOS/Views/LoginView.swift`
  - 移除登录页公开测试账号信息。
  - 将用户协议和隐私政策改为可点击入口，并使用内置浏览器打开。
- `AIChat-iOS/Views/SettingsView.swift`
  - 新增注销账号入口、二次确认、加载状态和错误提示。
  - 移除设置页对测试账号状态的用户可见提示，统一展示为已登录。
- `AIChat-iOS/Stores/AppStorage.swift`
  - 将登录会话存储从 `UserDefaults` 改为 Keychain。
  - 保留选中角色和引导完成状态在 `UserDefaults`。
- `AIChat-iOS/Stores/AppSessionStore.swift`
  - 新增账号删除成功后的本地账号状态清理方法。
- `AIChat-iOS/Services/LoginService.swift`
  - 新增 `DELETE /account` 注销账号接口调用。
- `AIChat-iOS/Models/APIResponses.swift`
  - 新增账号删除响应模型。

## 本次完成功能

- 登录页不再向正式用户展示测试账号。
- App 内可打开用户协议和隐私政策链接。
- 设置页可发起注销账号请求；成功后清理本地登录态、选中角色和引导状态。
- 访问 token 不再保存到 `UserDefaults`，改由 Keychain 保存。
- 生成了上架所需的协议文档草稿。

## 当前仍未完成的内容

- `AppLegalLinks` 中仍是 Notion 占位链接，上架前必须替换为公开可访问的正式 Notion URL。
- 后端需要实际上线 `DELETE /account`；否则注销账号会显示接口失败。
- 协议正文仍包含运营主体、联系邮箱、地址、生效日期等占位符，需要发布前替换。

## 运行说明或注意事项

- 本次不迁移旧 `UserDefaults` 登录态，旧版本已登录用户升级后需要重新登录。
- 注销账号失败时不会清理本地有效登录态，用户可以重试或继续使用。

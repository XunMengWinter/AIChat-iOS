# 设置页用户资料接口接入

## 新增文件
- `AIChat-iOS/Models/UserProfile.swift`
  - 新增用户资料模型 `UserProfile`。
  - 新增资料保存请求体 `UserProfileInput`。

## 修改文件
- `AIChat-iOS/Models/APIResponses.swift`
  - 新增用户资料获取与更新响应模型。

- `AIChat-iOS/Services/LoginService.swift`
  - 新增 `GET /account/profile` 用户资料获取接口。
  - 新增 `PUT /account/profile` 用户资料保存接口。

- `AIChat-iOS/ViewModels/SettingsViewModel.swift`
  - 新增用户资料加载、编辑表单状态和保存逻辑。
  - 支持昵称、性别、生日、城市、职业、兴趣、回复偏好。

- `AIChat-iOS/Views/SettingsView.swift`
  - 在设置页账号信息下方新增用户资料卡片。
  - 增加资料加载状态、保存状态、成功提示和错误提示。

- `AIChat-iOS/Utilities/AppDateFormatter.swift`
  - 新增用户资料生日 `yyyy-MM-dd` 格式化器。

## 完成功能
- 设置页进入后自动加载当前用户资料。
- 可在设置页直接编辑并保存用户资料。
- 保存时使用 Bearer JWT 调用云端资料接口。
- 兴趣支持使用中文逗号、英文逗号、顿号或换行分隔。
- 回复偏好保存到 `preferences.reply_style`。

## 当前仍未完成
- 暂未接入长期记忆 `/account/memories`。
- 暂未对 `preferences` 的其他动态字段提供独立编辑 UI。

## 验证说明
- 已执行 iPhone 17 模拟器 Debug 编译验证：
  - `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
  - 结果：`BUILD SUCCEEDED`

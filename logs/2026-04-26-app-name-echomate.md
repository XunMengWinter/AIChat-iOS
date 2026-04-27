# 2026-04-26 App 名称更新

## 本次新增文件

- `AIChat-iOS/en.lproj/InfoPlist.strings`
  - 新增英文环境下的 App 显示名称，显示为 `EchoMate`。
- `AIChat-iOS/zh-Hans.lproj/InfoPlist.strings`
  - 新增简体中文环境下的 App 显示名称，显示为 `伴语`。
- `logs/2026-04-26-app-name-echomate.md`
  - 记录本次 App 命名调整的改动内容。

## 本次修改文件

- `AIChat-iOS.xcodeproj/project.pbxproj`
  - 将 Debug 和 Release 配置中的 `CFBundleDisplayName` 默认值从 `AI 聊天` 改为 `伴语`。
  - 增加 `zh-Hans` 到工程本地化区域，配合中文 App 名称资源。
- `README.md`
  - 将项目展示名称更新为 `伴语 EchoMate`。
  - 补充中文名“伴语”和英文名 “EchoMate” 的说明。

## 本次完成功能

- App 在中文环境下使用名称 `伴语`。
- App 在英文环境下通过 InfoPlist 本地化使用名称 `EchoMate`。
- 保留原有 Xcode target、bundle identifier 和工程目录名称，避免影响构建、签名与现有工程引用。

## 当前仍未完成的内容

- 未重命名 Xcode target、scheme、bundle identifier 和源码目录。
- 未增加更多语言的 App 名称本地化。

## 运行说明或注意事项

- iOS 主屏幕显示名称由设备语言和 `InfoPlist.strings` 决定。
- 如需在所有语言环境统一显示中文名，可删除英文 `InfoPlist.strings` 或将英文值也改为 `伴语`。

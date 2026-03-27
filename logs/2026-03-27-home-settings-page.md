# 本次改动日志

## 新增文件
- `AIChat-iOS/Views/SettingsView.swift`
- `logs/2026-03-27-home-settings-page.md`

## 修改文件
- `AIChat-iOS/Stores/AppSessionStore.swift`
- `AIChat-iOS/ContentView.swift`
- `AIChat-iOS/Views/HomeView.swift`

## 文件作用
- `AIChat-iOS/Views/SettingsView.swift`：新增设置页，提供账号信息展示、返回首页入口和退出登录操作。
- `AIChat-iOS/Stores/AppSessionStore.swift`：扩展全局页面状态，新增设置页跳转与退出登录逻辑，并修正无登录态时的初始页面判断。
- `AIChat-iOS/ContentView.swift`：把设置页接入根页面分发流程。
- `AIChat-iOS/Views/HomeView.swift`：在首页右上角新增设置按钮，并接入跳转。
- `logs/2026-03-27-home-settings-page.md`：记录本次功能改动、验证结果与剩余事项。

## 本次完成的功能
- 在首页右上角新增了一个带阴影和磨砂感的设置按钮。
- 用户点击设置按钮后，可进入新的设置页。
- 设置页提供了当前登录账号信息展示。
- 设置页提供了退出登录按钮，并加入二次确认。
- 退出登录后会清除本地登录态并返回登录页。
- 修正了无登录态但已完成选角时的启动落点，使其回到登录页而不是重新进入选角页。

## 当前仍未完成的内容
- 设置页目前只包含基础账号信息和退出登录，没有接入更多设置项。
- 还没有基于 Figma 对设置页做更细的逐像素视觉校对。

## 运行说明或注意事项
- 本次改动需要重新编译 App 以验证新页面和退出登录流程。
- 如果后续要扩展设置页，可继续沿用当前卡片式结构新增设置项。

## 验证结果
- 已于 2026-03-27 使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 完成编译验证。
- 编译结果为 `BUILD SUCCEEDED`。
- 编译过程中仅出现 `AppIntents.framework` metadata skipped 警告，不影响本次功能交付。

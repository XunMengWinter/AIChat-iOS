# 本次改动日志

## 新增文件
- `logs/2026-03-27-home-toolbar-navigation-fix.md`

## 修改文件
- `AIChat-iOS/ContentView.swift`

## 文件作用
- `AIChat-iOS/ContentView.swift`：负责根据 `AppSessionStore.screen` 切换当前主界面，并承载首页所需的导航容器。
- `logs/2026-03-27-home-toolbar-navigation-fix.md`：记录本次首页 toolbar 不显示问题的原因、修复内容与验证说明。

## 本次完成的功能
- 修复了首页 `HomeView` 中 `.toolbar` 不显示的问题。
- 为首页补充了 `NavigationStack`，让 `ToolbarItem(placement: .topBarTrailing)` 有可挂载的导航栏宿主。
- 保持首页原有视觉风格，隐藏了导航栏背景，避免影响现有渐变和顶部布局。

## 当前仍未完成的内容
- 目前只有首页使用系统导航栏承载 toolbar，设置页和聊天页仍然使用自定义顶栏。
- 如果后续希望统一全局导航行为，还需要再梳理页面切换方式与返回路径。

## 运行说明或注意事项
- `toolbar` 顶部栏位（如 `.topBarTrailing`）需要处在 `NavigationStack` 或 `NavigationView` 这类导航容器中，否则不会显示。
- 本次修复不改变现有页面路由逻辑，设置页仍然通过 `sessionStore.showSettings()` 切换。

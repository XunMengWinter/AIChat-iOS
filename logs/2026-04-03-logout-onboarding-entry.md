# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-04-03-logout-onboarding-entry.md`

## 本次修改了哪些文件
- `AIChat-iOS/Stores/AppSessionStore.swift`
- `AIChat-iOS/Views/SettingsView.swift`

## 每个文件的作用
- `AIChat-iOS/Stores/AppSessionStore.swift`
  - 负责全局页面路由、登录状态与引导状态判定。
- `AIChat-iOS/Views/SettingsView.swift`
  - 负责设置页展示与退出登录交互。
- `logs/2026-04-03-logout-onboarding-entry.md`
  - 记录本次退出登录与未登录入口路由调整的改动内容。

## 本次完成了哪些功能
- 调整了全局初始页面判定逻辑。
- 现在只要当前没有登录会话，App 启动后会进入引导页，而不是登录页。
- 现在从设置页退出登录后，会回到引导页。
- 同步更新了设置页中的退出提示文案，使其与实际行为一致。

## 当前仍未完成的内容
- 未修改登录成功后的主流程，用户在引导页点击继续后仍会进入登录页完成登录。
- 未改动已选角色持久化逻辑，退出登录后仍会保留当前已选角色。

## 运行说明或注意事项
- 本次改动只涉及页面路由与文案，不影响网络层与聊天接口。
- 已按项目要求执行 iPhone 17 模拟器构建验证。
- 本次构建过程中产生的临时目录会在任务结束前清理。

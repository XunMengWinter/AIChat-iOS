# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-onboarding-carousel-loop.md`

## 本次修改了哪些文件
- `AIChat-iOS/Views/OnboardingView.swift`

## 每个文件的作用
- `AIChat-iOS/Views/OnboardingView.swift`
  负责引导页标题区、角色选择卡片区、分页指示器和开始按钮的整体展示与交互。
- `logs/2026-03-28-onboarding-carousel-loop.md`
  记录本次引导页 carousel 循环滚动与视觉层级优化的实现内容和验证结果。

## 本次完成了哪些功能
- 将原先的 `TabView` 角色切换改为吸附式横向 carousel。
- 支持左右循环滚动：
  - 使用三段虚拟数据实现循环效果
  - 滑到首尾区域后会无感回到中段对应位置
- 支持两侧卡片露出一部分：
  - 当前卡片宽度缩窄，左右卡片会在同屏显示一点作为预览
- 强化当前卡片的视觉主次：
  - 当前卡片更大、更亮、阴影更强
  - 左右卡片缩小并降低透明度
- 分页指示器现在跟随当前居中的卡片更新，不受虚拟循环数据影响。

## 当前仍未完成的内容
- 尚未在模拟器内手动验证快速连续横向拖动时的手感。
- 如果后续希望卡片在拖动过程中按距离连续缩放，而不是吸附后切换主次，还可以继续细化动画。

## 运行说明或注意事项
- 已使用以下命令完成编译验证：
  - `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build`
- 编译结果为 `BUILD SUCCEEDED`。
- 编译输出中的 `Metadata extraction skipped. No AppIntents.framework dependency found.` 为非阻塞 warning。
- 已清理本次任务生成的项目内临时构建目录 `.derivedData`。

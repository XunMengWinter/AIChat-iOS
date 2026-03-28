# 本次改动日志

## 本次新增了哪些文件
- `logs/2026-03-28-chat-keyboard-experience.md`

## 本次修改了哪些文件
- `AIChat-iOS/Views/ChatView.swift`

## 每个文件的作用
- `AIChat-iOS/Views/ChatView.swift`
  负责聊天页的整体布局、消息列表、快捷话题、底部输入区与图片选择入口。
- `logs/2026-03-28-chat-keyboard-experience.md`
  记录本次聊天页软键盘输入体验重做后的改动内容与验证结果。

## 本次完成了哪些功能
- 将聊天页改为“顶部栏固定，聊天内容区单独跟随键盘”的布局：
  - 背景层继续全屏铺满，不参与键盘位移
  - 顶部标题栏与错误提示条保持固定，不随键盘上移
  - 仅聊天列表、快捷话题条和底部输入区根据键盘高度整体上移
- 保持现有输入框、图片选择按钮、发送按钮、草稿图片预览卡片的视觉样式不变，仅调整聊天内容区的键盘避让方式。
- 键盘弹起时自动隐藏快捷话题条，为输入区和消息列表腾出更多高度。
- 为消息列表补充 `scrollDismissesKeyboard(.interactively)`，支持上下拖动时交互式收起键盘。
- 新增底部滚动触发逻辑，在输入框聚焦、键盘弹起或点击快捷话题后主动滚动到底部，减少最后一条消息被底部输入区顶住的情况。

## 当前仍未完成的内容
- 尚未在真实运行中的 iPhone 17 模拟器里逐项手测键盘弹起、图片草稿和发送按钮的触达表现。
- 如果后续发现第三方输入法或横屏场景下键盘高度计算有偏差，需要再针对极端场景微调动画与偏移量。

## 运行说明或注意事项
- 聊天页的发送流程、历史加载、流式输出和图片处理逻辑未改动，本次只调整视图层的键盘避让与底部交互体验。
- 需要使用 iPhone 17 模拟器重新验证：
  - 聊天背景在键盘弹起时保持静止，不出现整体上推
  - 顶部标题栏在键盘弹起时保持固定
  - 键盘弹起后输入框和发送按钮始终可见并可点击
  - 聊天列表会和底部输入区一起被键盘顶起
  - 快捷话题条在键盘弹起时隐藏，收起键盘后恢复
  - 上下拖动消息列表可交互式收起键盘
- 已使用 `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug -derivedDataPath .derivedData build` 验证编译通过。
- 编译输出中 `Metadata extraction skipped. No AppIntents.framework dependency found.` 为非阻塞 warning，不影响本次聊天页键盘体验重做。

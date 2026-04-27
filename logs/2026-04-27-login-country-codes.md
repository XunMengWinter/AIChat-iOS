# 登录页热门国家地区号

## 新增文件
- `AIChat-iOS/Models/CountryDialCode.swift`
  - 新增国家地区号模型。
  - 内置登录页热门国家/地区列表。
  - 提供登录接口使用的 `apiValue` 和设置页展示用的区号格式化方法。

## 修改文件
- `AIChat-iOS/ViewModels/LoginViewModel.swift`
  - 新增当前选中的国家地区号状态。
  - 发送验证码和登录时传入所选 `countryCode`。
  - 手机号输入长度按当前地区号限制。

- `AIChat-iOS/Views/LoginView.swift`
  - 将固定 `+86` 改为可点击的地区号按钮。
  - 新增底部弹窗地区号选择列表。
  - 切换地区号后同步更新手机号输入限制。

- `AIChat-iOS/Views/SettingsView.swift`
  - 国家区号展示统一格式化为 `+86`、`+1` 等形式。

## 完成功能
- 登录页默认选中中国 `+86`。
- 支持中国、美国、加拿大、日本、新加坡、澳大利亚、新西兰、英国、法国、西班牙、意大利、韩国、德国、印度、泰国、马来西亚等热门国家/地区号。
- 登录接口继续传不带 `+` 的 `country_code` 字符串。

## 当前仍未完成
- 暂未支持全量国家/地区号。
- 暂未支持搜索国家/地区号。
- 暂未持久化上次选择的地区号。

## 验证说明
- 已执行 iPhone 17 模拟器 Debug 编译验证：
  - `xcodebuild -project AIChat-iOS.xcodeproj -scheme AIChat-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build`
  - 结果：`BUILD SUCCEEDED`

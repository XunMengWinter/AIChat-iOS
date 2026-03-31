# 本次改动日志

## 本次新增文件
- `logs/2026-03-30-alamofire-network-layer.md`
  - 记录本次接入 Alamofire 网络层的改动说明、验证结果和注意事项。

## 本次修改文件
- `AIChat-iOS/Services/APIClient.swift`
  - 将底层网络实现从 `URLSession` 切换为 `Alamofire.Session`。
  - 保留现有 `makeRequest`、`encodeBody`、`perform`、`stream` 对外接口，避免影响 `LoginService`、`ChatService` 和上层 ViewModel。
  - 普通 JSON 请求改为通过 Alamofire 发起并统一处理响应、解码和错误映射。
  - 聊天 SSE 流改为基于 Alamofire 的 `DataStreamRequest` 实现，并保留原有流式分片解析与增量回调逻辑。

- `AIChat-iOS.xcodeproj/project.pbxproj`
  - 将 `Alamofire` 作为 Swift Package 依赖接入到 iOS App target。

- `AIChat-iOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
  - 锁定 Swift Package 解析结果。
  - 本次新增 `Alamofire 5.11.1`，保留现有 `Nuke 12.9.0`。

## 本次完成的功能
- 已为项目接入 Alamofire。
- 已将项目网络层底座切换到 Alamofire。
- 已保持现有登录、历史记录、角色列表、清空聊天、流式聊天等 Service 调用方式不变。
- 已保留原有 API 错误映射逻辑，包括：
  - `401` 转 `APIError.unauthorized`
  - 后端错误体解析为 `APIError.server`
  - 解码失败转 `APIError.decodingFailed`
  - 网络失败统一转 `APIError.network`
- 已保留聊天流的 SSE 行分割、`data:` 事件提取、`[DONE]` 处理和首包时间统计逻辑。

## 当前仍未完成的内容
- 还没有引入全局请求拦截器、统一重试策略或 token 自动刷新机制。
- 还没有为网络层补充单元测试。
- 目前上传场景仍沿用现有 Base64 图片参数方式，未扩展 Alamofire 的 multipart 上传封装。

## 运行说明或注意事项
- 本次构建验证使用的是 iPhone 17 模拟器设备。
- 构建验证命令已通过，目标为 Debug + iOS Simulator。
- 这次任务中为构建临时生成的 `.derivedData`、`.home`、`.spm`、`.moduleCache` 已清理。

# NXBoot 增强功能说明

## 新增功能概述

在原有重构的基础上，新增了**用户可配置的高级设置**功能，让用户可以根据自己的需求调整系统行为。

---

## 🎛️ 新增的可配置项

### 1. USB 读取超时 (USB Read Timeout)

**位置**: Settings → USB Communication → Read Timeout

**功能**: 控制从 USB 设备读取数据时的超时时间。

**配置范围**:
- 最小值: 100 ms
- 最大值: 10,000 ms (10 秒)
- 默认值: 1,000 ms (1 秒)

**使用场景**:
- **降低超时**: 如果你的设备响应很快，可以降低超时值以提高响应速度
- **增加超时**: 如果经常遇到读取超时错误，可以增加超时值以适应较慢的设备

**技术实现**:
- 存储在 `UserDefaults` 中的 `usbReadTimeoutMS` 键
- `DeviceManager` 动态读取并应用到 USB 通信
- 自动验证和限制在有效范围内

---

### 2. 系统日志限制 (System Log Limit)

**位置**: Settings → Logging → System Log Limit

**功能**: 控制内存中保留的系统日志条目数量。

**配置范围**:
- 最小值: 100 条
- 最大值: 10,000 条
- 默认值: 500 条

**使用场景**:
- **减少内存占用**: 如果内存有限，可以降低日志限制
- **保留更多历史**: 如果需要查看更长的日志历史，可以增加限制

**技术实现**:
- 存储在 `UserDefaults` 中的 `maxSystemLogEntries` 键
- `Logger` 动态读取并在添加日志时应用限制
- 超过限制时自动删除最旧的条目

---

### 3. 设备日志限制 (Device Log Limit)

**位置**: Settings → Logging → Device Log Limit

**功能**: 控制内存中保留的设备输出日志条目数量。

**配置范围**:
- 最小值: 100 条
- 最大值: 10,000 条
- 默认值: 1,000 条

**使用场景**:
- **调试模式**: 增加限制以捕获更多设备输出
- **正常使用**: 使用默认值或更低的值以节省内存

**技术实现**:
- 存储在 `UserDefaults` 中的 `maxDeviceLogEntries` 键
- `Logger` 动态读取并在添加日志时应用限制
- 设备日志通常比系统日志更多，因此默认值更高

---

## 🔄 重置到默认值

**位置**: Settings → Advanced → Reset to Defaults

**功能**: 一键将所有高级设置恢复到默认值。

**重置的设置**:
- USB 读取超时 → 1,000 ms
- 系统日志限制 → 500 条
- 设备日志限制 → 1,000 条
- 显示通知 → 开启

**安全措施**:
- 显示确认对话框，防止误操作
- 不会影响已导入的 payload 或默认 payload 选择

---

## 🎨 UI 改进

### 设置界面增强

1. **分组更清晰**:
   - General (通用设置)
   - Notifications (通知设置)
   - USB Communication (USB 通信设置) - **新增**
   - Logging (日志设置) - **新增**
   - Advanced (高级操作)

2. **输入验证**:
   - 所有数值输入都有实时验证
   - 超出范围的值会自动调整到有效范围
   - 显示有效范围提示

3. **帮助文本**:
   - 每个设置都有说明文字
   - 解释设置的作用和影响

4. **窗口尺寸**:
   - 从 500px 增加到 550px 以容纳新内容

---

## 📝 代码架构改进

### Constants.swift 更新

```swift
// 从固定值改为默认值 + 范围限制
static let defaultUSBReadTimeoutMS: UInt32 = 1000
static let minUSBReadTimeoutMS: UInt32 = 100
static let maxUSBReadTimeoutMS: UInt32 = 10000

static let defaultMaxSystemLogEntries = 500
static let defaultMaxDeviceLogEntries = 1000
static let minLogEntries = 100
static let maxLogEntriesLimit = 10000
```

### DeviceManager.swift 更新

```swift
// 新增计算属性，从 UserDefaults 动态读取
var usbReadTimeoutMS: UInt32 {
    let timeout = UserDefaults.standard.object(forKey: "usbReadTimeoutMS") as? UInt32 
        ?? AppConstants.defaultUSBReadTimeoutMS
    return max(AppConstants.minUSBReadTimeoutMS, 
               min(timeout, AppConstants.maxUSBReadTimeoutMS))
}
```

### Logger.swift 更新

```swift
// 新增计算属性，从 UserDefaults 动态读取
var maxSystemLogEntries: Int {
    UserDefaults.standard.object(forKey: "maxSystemLogEntries") as? Int 
        ?? AppConstants.defaultMaxSystemLogEntries
}

var maxDeviceLogEntries: Int {
    UserDefaults.standard.object(forKey: "maxDeviceLogEntries") as? Int 
        ?? AppConstants.defaultMaxDeviceLogEntries
}
```

---

## 🔍 使用示例

### 场景 1: 设备响应慢，经常超时

**问题**: 在 Logs 中看到很多 "Read error: 0xE000404F" (超时错误)

**解决方案**:
1. 打开 Settings
2. 找到 "USB Communication" → "Read Timeout"
3. 将值从 1000 增加到 2000 或 3000
4. 重新连接设备测试

### 场景 2: 需要调试，想看更多日志

**问题**: 设备输出很多信息，但只能看到最近的 1000 条

**解决方案**:
1. 打开 Settings
2. 找到 "Logging" → "Device Log Limit"
3. 将值从 1000 增加到 5000 或更高
4. 新的日志会保留更多条目

### 场景 3: 内存占用过高

**问题**: 应用运行一段时间后内存占用很高

**解决方案**:
1. 打开 Settings
2. 减少日志限制:
   - System Log Limit: 500 → 200
   - Device Log Limit: 1000 → 500
3. 或者定期清空日志 (Logs 视图中的 Clear 按钮)

---

## ⚙️ 技术细节

### 数据持久化

所有设置都存储在 `UserDefaults` 中，应用重启后保持不变：

```swift
// 存储键
- "usbReadTimeoutMS": UInt32
- "maxSystemLogEntries": Int
- "maxDeviceLogEntries": Int
- "showNotifications": Bool
- "defaultPayloadID": String
```

### 实时生效

- **USB 超时**: 下次 USB 读取操作时生效
- **日志限制**: 下次添加日志时生效
- 无需重启应用

### 输入验证

使用 SwiftUI 的 `.onChange` 修饰符实时验证：

```swift
.onChange(of: usbReadTimeoutMS) { _, newValue in
    let clamped = max(Int(AppConstants.minUSBReadTimeoutMS), 
                      min(newValue, Int(AppConstants.maxUSBReadTimeoutMS)))
    if clamped != newValue {
        usbReadTimeoutMS = clamped
    }
}
```

---

## 📊 性能影响

### USB 超时调整

- **降低超时**: 
  - ✅ 更快的错误检测
  - ⚠️ 可能增加误报超时
  
- **增加超时**:
  - ✅ 减少超时错误
  - ⚠️ 错误检测变慢

### 日志限制调整

- **降低限制**:
  - ✅ 减少内存占用
  - ⚠️ 历史日志更少
  
- **增加限制**:
  - ✅ 保留更多历史
  - ⚠️ 内存占用增加

**内存估算**:
- 每条日志约 100-200 字节
- 1000 条日志约 100-200 KB
- 10000 条日志约 1-2 MB

---

## 🎯 最佳实践

### 推荐设置

**日常使用**:
- USB 超时: 1000 ms (默认)
- 系统日志: 500 条 (默认)
- 设备日志: 1000 条 (默认)

**调试模式**:
- USB 超时: 2000-3000 ms
- 系统日志: 1000-2000 条
- 设备日志: 5000-10000 条

**低内存设备**:
- USB 超时: 1000 ms (默认)
- 系统日志: 200-300 条
- 设备日志: 500-800 条

---

## 🔧 故障排除

### 设置不生效？

1. 检查输入的值是否在有效范围内
2. 尝试 "Reset to Defaults" 然后重新设置
3. 重启应用

### 输入框无法输入？

- 确保输入的是数字
- 使用数字键盘或主键盘的数字键

### 想恢复默认设置？

- 点击 "Reset to Defaults" 按钮
- 或者手动输入默认值

---

## 📚 相关文件

### 修改的文件

1. `NXBootApp/Models/Constants.swift`
   - 添加默认值和范围常量

2. `NXBootApp/Models/DeviceManager.swift`
   - 添加 `usbReadTimeoutMS` 计算属性
   - 使用动态超时值

3. `NXBootApp/Models/Logger.swift`
   - 添加 `maxSystemLogEntries` 和 `maxDeviceLogEntries` 计算属性
   - 使用动态日志限制

4. `NXBootApp/Views/SettingsView.swift`
   - 完全重写，添加新的设置 UI
   - 添加输入验证和重置功能

---

## ✅ 构建验证

- ✅ 项目生成成功
- ✅ 编译成功
- ✅ 所有设置可正常保存和读取
- ✅ 输入验证正常工作
- ✅ 重置功能正常工作

---

## 🚀 未来可能的增强

1. **导出/导入设置**: 允许用户保存和分享设置配置
2. **预设配置**: 提供"调试模式"、"性能模式"等预设
3. **自动调整**: 根据设备性能自动调整超时值
4. **统计信息**: 显示日志使用情况和内存占用
5. **高级 USB 设置**: 缓冲区大小、重试次数等

---

**更新日期**: 2026-05-31  
**版本**: 2.1.0+  
**状态**: ✅ 已实现并测试

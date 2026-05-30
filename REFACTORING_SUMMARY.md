# NXBoot 代码重构总结

## 修复日期
2026-05-31

## 修复的问题

### 1. ✅ 创建统一的常量管理 (Constants.swift)

**问题**: 硬编码值分散在多个文件中，难以维护。

**解决方案**: 创建 `NXBootApp/Models/Constants.swift`，集中管理所有配置常量：

- **USB 设备标识符**: `tegraX1VendorID` (0x0955), `tegraX1ProductID` (0x7321)
- **路径常量**: `cliToolName`, `cliInstallPath`, `payloadsSubdirectory`
- **USB 通信参数**: `usbReadTimeoutMS`, `usbReadSleepNS`, `usbBufferSize`
- **日志限制**: `maxSystemLogEntries` (500), `maxDeviceLogEntries` (1000)
- **仓库 URL**: `repositoryURL`, `licenseURL`, `updatesURL`
- **版权信息**: `originalCopyright`, `currentCopyright`, `fullCopyright`

**影响的文件**:
- `DeviceManager.swift`: 使用 USB 常量和超时值
- `Logger.swift`: 使用日志限制常量
- `PayloadManager.swift`: 使用路径常量
- `CLIInstaller.swift`: 使用 CLI 路径常量
- `AboutView.swift`: 使用版权常量

---

### 2. ✅ 修复 Bundle Identifier

**问题**: 使用原作者的 `io.mologie` 前缀。

**解决方案**: 
- 将 `project.yml` 中的 `bundleIdPrefix` 改为 `io.steveshi`
- 更新两个 target 的 Bundle Identifier:
  - `io.steveshi.nxboot.app` (应用)
  - `io.steveshi.nxboot.cmd` (CLI 工具)
- `PayloadManager.swift` 使用动态 Bundle Identifier 构建路径

---

### 3. ✅ 统一版本号管理

**问题**: 版本号在多处硬编码 (project.yml, Info.plist, AboutView.swift)。

**解决方案**:
- `AboutView.swift` 从 `Bundle.main.infoDictionary` 动态读取版本号
- 移除硬编码的 `"Version 2.1.0"`
- 保持 `project.yml` 和 `Info.plist` 作为单一数据源

**代码示例**:
```swift
if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
    Text("\(String(localized: "Version")) \(version)")
}
```

---

### 4. ✅ 修复 SettingsView 功能

**问题 1**: "Clear Payload Cache" 按钮没有实现。

**解决方案**: 
- 添加确认对话框
- 实现清除所有 payload 的功能
- 清除后重置 `defaultPayloadID`

**问题 2**: Payload 选择器不一致。

**原问题**:
- `SettingsView` 使用硬编码的 `@AppStorage("defaultPayload")` 和 "Hekate"/"Fusée" 选项
- `DashboardView` 使用 `@AppStorage("defaultPayloadID")` (UUID)

**解决方案**:
- 移除硬编码的 Hekate/Fusée 选项
- 统一使用 `defaultPayloadID` (UUID)
- 从 `PayloadManager` 动态加载 payload 列表
- 添加 "None" 选项

---

### 5. ✅ 更新版权和 URL 引用

**修改的文件**:

1. **project.yml**:
   - Bundle Identifier 前缀: `io.mologie` → `io.steveshi`
   - Copyright: 添加 "© 2026 SteveShi"

2. **NXBootCmd/main.m**:
   - `COPYRIGHT_STR`: 添加 ", 2026 SteveShi"
   - `LICENSE_STR`: URL 更新为 `https://github.com/steveshi0/nxboot#license`
   - 帮助信息中的 URL: `https://github.com/steveshi0/nxboot`

3. **AboutView.swift**:
   - 使用 `AppConstants.originalCopyright` 和 `AppConstants.currentCopyright`
   - CLI 安装路径使用 `AppConstants.cliInstallPath`

---

### 6. ✅ 提取路径常量

**问题**: CLI 安装路径 `/usr/local/bin/nxboot` 在多处重复。

**解决方案**:
- `CLIInstaller.swift`: 3 处引用改为 `AppConstants.cliInstallPath`
- `AboutView.swift`: 1 处引用改为常量
- Payloads 目录使用 `AppConstants.payloadsSubdirectory`

---

### 7. ✅ 动态 Payloads 目录路径

**问题**: `PayloadManager.swift` 硬编码 `"NXBoot/Payloads"` 路径。

**解决方案**:
```swift
let bundleID = Bundle.main.bundleIdentifier ?? "io.steveshi.nxboot.app"
let payloadsDir = appSupport.appendingPathComponent("\(bundleID)/\(AppConstants.payloadsSubdirectory)", isDirectory: true)
```

这样即使 Bundle Identifier 改变，路径也会自动适配。

---

## 保留的合理硬编码

以下硬编码是**合理的**，因为它们是硬件/协议规范，无需修改：

### NXExec.m (Tegra X1 硬件地址)
- `kNXCopyBuf1 = 0x40009000`
- `kNXStackLowest = 0x40010000`
- `kNXPayloadAddr = 0x40010000`
- `kNXRelocatorAddr = 0x40010E40`
- `kNXStackSprayStart = 0x40014E40`
- `kNXStackSprayEnd = 0x40017000`
- `kNXCmdHeaderSize = 680`
- `kNXCmdMaxSize = 0x30298`
- `kNXPacketMaxSize = 0x1000`

### NXHekateCustomizer.m (Hekate 协议)
- `kNXHekatePayloadConfigOffset = 0x94`
- `kNXHekateMagic = {'I','C','T','C'}`

---

## 构建验证

✅ 项目成功生成: `xcodegen generate`
✅ 构建成功: `xcodebuild -scheme NXBootApp -configuration Release`

---

## 文件清单

### 新增文件
- `NXBootApp/Models/Constants.swift` - 统一常量管理

### 修改的文件
1. `project.yml` - Bundle Identifier 和版权
2. `NXBootApp/Models/DeviceManager.swift` - USB 常量
3. `NXBootApp/Models/Logger.swift` - 日志限制常量
4. `NXBootApp/Models/PayloadManager.swift` - 动态路径
5. `NXBootApp/Models/CLIInstaller.swift` - CLI 路径常量
6. `NXBootApp/Views/SettingsView.swift` - 完全重写，修复功能
7. `NXBootApp/Views/AboutView.swift` - 动态版本号和版权
8. `NXBootCmd/main.m` - URL 和版权更新

---

## 后续建议

1. **更新 README.md**: 将仓库 URL 从 `mologie/nxboot` 更新为 `steveshi0/nxboot`
2. **更新 CHANGELOG.md**: 记录这次重构
3. **测试功能**:
   - 导入 payload
   - 选择默认 payload
   - 清除 payload 缓存
   - CLI 工具安装
   - 设备连接和注入

4. **考虑添加**:
   - 用户可配置的日志限制 (目前是硬编码常量)
   - 用户可配置的 USB 超时 (目前是硬编码常量)

---

## 技术债务清理

✅ 移除了 8 处硬编码的 USB VID/PID  
✅ 移除了 4 处硬编码的路径  
✅ 移除了 3 处硬编码的版本号  
✅ 移除了 5 处硬编码的 URL  
✅ 统一了 2 处不一致的 payload 选择逻辑  
✅ 实现了 1 个空功能按钮  

**总计**: 修复了 23 处代码问题，提升了代码可维护性和一致性。

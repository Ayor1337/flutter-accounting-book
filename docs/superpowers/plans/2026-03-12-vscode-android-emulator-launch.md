# VSCode 安卓模拟器调试配置 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 VSCode 在启动 Flutter 调试前自动拉起 `Pixel_9` 安卓模拟器，并等待设备可用后再附加到项目。

**Architecture:** 保留现有 Dart/Flutter 调试配置，在 `launch.json` 中通过 `preLaunchTask` 串接一个新的 VSCode shell task。该 task 使用 `flutter emulators --launch Pixel_9` 启动模拟器，再通过 `adb` 轮询等待设备注册和系统启动完成，最后把控制权交回 Flutter 调试器。

**Tech Stack:** VSCode `launch.json`、VSCode `tasks.json`、Flutter CLI、Android `adb`、PowerShell

---

## Chunk 1: VSCode 调试与任务编排

### Task 1: 调整调试入口

**Files:**
- Modify: `.vscode/launch.json`
- Create: `.vscode/tasks.json`

- [ ] **Step 1: 记录当前调试配置**

确认 `.vscode/launch.json` 目前使用 `type: "dart"` 和 `toolArgs: ["-d", "android"]`，避免改动 Flutter 的启动目标选择逻辑。

- [ ] **Step 2: 修改调试配置以接入前置任务**

在现有配置上新增 `preLaunchTask: "launch-android-emulator"`，让 VSCode 每次启动调试前先执行模拟器启动任务。

- [ ] **Step 3: 新建模拟器任务**

在 `.vscode/tasks.json` 中新增 PowerShell shell task，执行 `flutter emulators --launch Pixel_9`，并通过 `adb` 轮询等待模拟器出现在 `adb devices` 且 `sys.boot_completed=1`。

- [ ] **Step 4: 验证配置文件内容**

运行：

```powershell
Get-Content .vscode\launch.json
Get-Content .vscode\tasks.json
```

预期：`launch.json` 包含 `preLaunchTask`，`tasks.json` 包含 `launch-android-emulator` 任务和 `Pixel_9` 模拟器 ID。

- [ ] **Step 5: 命令级验证**

运行：

```powershell
flutter emulators
```

预期：输出中包含唯一模拟器 `Pixel_9`，与任务配置一致。

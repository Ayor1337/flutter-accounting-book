# Settings Back Navigation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复从首页进入设置页后返回直接退出应用的问题，并补上回归测试。

**Architecture:** 保持现有路由结构不变，只修正首页到设置页的导航语义。通过 widget test 验证设置页是以可回退的栈式导航打开，而不是替换当前路由。

**Tech Stack:** Flutter, flutter_test, flutter_riverpod, go_router

---

### Task 1: 补充导航回归测试

**Files:**
- Create: `test/features/settings/settings_navigation_test.dart`
- Modify: `lib/features/home/home_page.dart`

- [ ] **Step 1: 写出失败测试**

创建一个最小路由树，复用真实 `HomePage`、`SettingsPage` 与 `MainScaffold`，断言从首页进入设置页后 `router.canPop()` 为 `true`，并且执行 `pop()` 后回到首页。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/settings/settings_navigation_test.dart`
Expected: FAIL，因为当前首页进入设置页使用的是替换式导航，设置页没有上一层可返回栈。

- [ ] **Step 3: 进行最小实现**

将 `lib/features/home/home_page.dart` 中设置按钮的导航从 `context.go('/settings')` 改为 `context.push('/settings')`。

- [ ] **Step 4: 重新运行测试确认通过**

Run: `flutter test test/features/settings/settings_navigation_test.dart`
Expected: PASS，且 `pop()` 后重新显示首页。

- [ ] **Step 5: 做一次结果验证**

如环境允许，再运行一次相关定向测试，确认没有引入新的导航回归。

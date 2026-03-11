# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 协作方式

当用户提出问题时，**优先提供解决方案、思路或建议供用户参考，而不是直接修改代码**。如需写代码，应先征得用户明确同意。

## Commands

```bash
# 获取依赖
flutter pub get

# 运行应用（Android）
flutter run

# 生成 Drift 代码（每次修改数据库表定义后必须运行）
dart run build_runner build --delete-conflicting-outputs

# 监听模式（开发期间自动重新生成）
dart run build_runner watch --delete-conflicting-outputs

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/core/database/transaction_dao_test.dart

# 代码格式化与分析
dart format lib/
flutter analyze
```

> **注意**：`pubspec.yaml` 目前依赖分类有误——`flutter_riverpod`、`drift`、`go_router`、`fl_chart` 等运行时依赖被放在 `dev_dependencies` 下，`drift_dev` 和 `build_runner` 被放在 `flutter:` 节点下。开始开发前需先修正依赖分类。

## 架构

**详细规划见 `PLAN.md`**，以下是关键架构要点。

### 技术栈

| 层次 | 选型 |
|------|------|
| 状态管理 | Riverpod（`flutter_riverpod`） |
| 本地数据库 | Drift（SQLite ORM，代码生成） |
| 路由 | go_router（声明式） |
| 图表 | fl_chart |
| UI | Material 3 |

### 代码分层

```
lib/
├── main.dart            # 入口，初始化 ProviderScope
├── app.dart             # GoRouter 路由表 + MaterialApp.router
├── core/
│   ├── database/        # Drift 数据库（表定义、DAO、主入口 app_database.dart）
│   ├── providers/       # Riverpod Provider（数据库、DAO 的 Provider 定义）
│   └── utils/           # 货币格式化、日期工具
├── features/            # 按功能模块划分，每个模块含 page + widgets + providers
│   ├── home/
│   ├── transaction/     # add/（记账页）、list/（账单列表）
│   ├── budget/
│   ├── analytics/
│   └── settings/
└── shared/
    ├── widgets/         # 跨模块公共组件（数字键盘、分类选择器等）
    └── theme/           # 亮色/暗色 ThemeData
```

### 数据模型

三张核心表，均通过 Drift 定义并生成代码：

- **Transaction**：`id, amount, type(income/expense), category_id, note, date, created_at`
- **Category**：`id, name, icon, color, type, is_default`
- **Budget**：`id, month(YYYY-MM), total_amount, category_id`（`category_id` 为 null 表示月总预算）

### Drift 工作流

表定义在 `lib/core/database/tables/`，DAO 在 `lib/core/database/daos/`，通过 `app_database.dart` 整合。**每次修改 `.dart` 表定义后必须重新运行 `build_runner` 生成 `.g.dart` 文件**，生成文件不提交到版本控制。

### 数据流

UI → Riverpod Provider（`StreamProvider` / `FutureProvider`）→ DAO → Drift → SQLite

首页和账单列表使用 `StreamProvider` 实现实时响应式更新，无需手动刷新。

### Android 最低要求

`android/app/build.gradle` 中 `minSdk` 需设置为 **21**（Drift SQLite 要求）。

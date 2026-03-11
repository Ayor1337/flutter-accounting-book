# 记账本 App 开发计划

## 技术选型

| 层次 | 选型 | 说明 |
|------|------|------|
| 状态管理 | `flutter_riverpod` | 轻量、类型安全，代码简洁 |
| 本地数据库 | `drift`（基于 SQLite） | 类型安全 ORM，支持响应式查询 |
| 图表 | `fl_chart` | Flutter 生态最成熟的图表库 |
| 路由 | `go_router` | 官方推荐，声明式路由 |
| UI | Material 3 | 原生 Android 感，开发快 |

## 项目结构

```
lib/
├── main.dart
├── app.dart                    # 路由、主题、Provider 配置
├── core/
│   ├── database/
│   │   ├── app_database.dart   # Drift 数据库定义
│   │   ├── tables/             # 表结构（transactions, categories, budgets）
│   │   ├── daos/               # 数据访问对象
│   │   └── seeds/              # 默认数据（分类）
│   ├── providers/              # Riverpod Provider
│   └── utils/
│       ├── currency_formatter.dart
│       └── date_utils.dart
├── features/
│   ├── home/                   # 首页：月度汇总卡片 + 最近账单
│   ├── transaction/
│   │   ├── add/                # 记账页
│   │   └── list/               # 账单列表（按日分组）
│   ├── budget/                 # 预算设置与进度
│   ├── analytics/              # 图表分析
│   └── settings/               # 设置（分类管理、主题）
└── shared/
    ├── widgets/                # 通用组件
    └── theme/                  # 主题配置
```

---

## 数据模型

### Transaction（账单）
```
id           INTEGER PRIMARY KEY
amount       REAL        金额（单位：元）
type         TEXT        income / expense
category_id  INTEGER     外键 → categories
note         TEXT        备注（可空）
date         DATE        账单日期
created_at   DATETIME    创建时间
```

### Category（分类）
```
id           INTEGER PRIMARY KEY
name         TEXT        分类名称
icon         TEXT        图标标识（Material Icons name）
color        INTEGER     颜色值（ARGB）
type         TEXT        income / expense
is_default   BOOLEAN
```

### Budget（预算）
```
id            INTEGER PRIMARY KEY
month         TEXT        格式 YYYY-MM
total_amount  REAL        月总预算
category_id   INTEGER     null = 总预算，非 null = 分类预算
```

---

## 主要依赖（pubspec.yaml）

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.0
  path: ^1.9.0
  go_router: ^14.0.0
  fl_chart: ^0.68.0
  intl: ^0.19.0

dev_dependencies:
  drift_dev: ^2.18.0
  build_runner: ^2.4.0
```

---

## 第一阶段：核心记账功能

### 任务 1：项目初始化
- [x] 更新 `pubspec.yaml`，添加所有依赖
- [x] 运行 `flutter pub get`
- [x] 配置 `android/app/build.gradle`，设置 `minSdk 21`

### 任务 2：数据库搭建
- [x] 创建 `lib/core/database/tables/transactions.dart`（Drift 表定义）
- [x] 创建 `lib/core/database/tables/categories.dart`
- [x] 创建 `lib/core/database/tables/budgets.dart`
- [ ] 创建 `lib/core/database/daos/transaction_dao.dart`（CRUD + 按月查询）
  - `insertTransaction` — 新增账单（记账页保存）
  - `updateTransaction` — 更新账单（编辑账单）
  - `deleteTransaction(id)` — 删除账单（滑动删除）
  - `watchTransactionsByMonth(month)` → `Stream` — 按月实时监听，按日期倒序（账单列表页）
  - `getRecentTransactions(limit)` → `Stream` — 最近 N 条账单（首页）
  - `getMonthlySummary(month)` → `Stream<(income, expense)>` — 当月收支合计，用 SQL `sum()` 聚合（首页汇总卡片）
  - `getMonthlyExpenseByCategory(month)` → `Future<List>` — 当月各分类支出（图表：饼图）
  - `getDailyExpense(month)` → `Future<List>` — 当月每日支出（图表：柱状图）
  - `getMonthlyTotals(months)` → `Future<List>` — 多月收支合计（图表：折线图近 6 个月）
- [ ] 创建 `lib/core/database/daos/category_dao.dart`
  - `watchCategoriesByType(type)` → `Stream` — 按类型实时监听分类（记账页分类选择器）
  - `getAllCategories()` → `Future<List>` — 全部分类（设置页）
  - `insertCategory` — 新增自定义分类
  - `deleteCategory(id)` — 删除分类（仅非默认）
  - `seedDefaultCategories()` — 写入默认分类，AppDatabase 初始化时调用
- [ ] 创建 `lib/core/database/daos/budget_dao.dart`
  - `watchBudgetsByMonth(month)` → `Stream` — 实时监听某月所有预算（预算页）
  - `upsertBudget` — 新增或更新预算，按 `month + category_id` 做 `insertOnConflictUpdate`
  - `deleteBudget(id)` — 删除单条预算
  - `getMonthlyBudget(month)` → `Future<Budget?>` — 获取月总预算（`category_id` 为 null）
  - `getCategoryBudgets(month)` → `Future<List>` — 获取某月所有分类预算
- [ ] 创建 `lib/core/database/app_database.dart`（Drift 主入口，整合所有表和 DAO）
- [ ] 运行 `dart run build_runner build` 生成 `.g.dart` 文件
- [ ] 创建 `lib/core/providers/database_provider.dart`（Riverpod Provider）

### 任务 3：默认分类数据
- [ ] 创建 `lib/core/database/seeds/default_categories.dart`
- [ ] 定义支出分类：餐饮、交通、购物、娱乐、住房、医疗、教育、其他
- [ ] 定义收入分类：工资、兼职、理财、其他
- [ ] 在 `AppDatabase` 初始化时检查并写入默认分类

### 任务 4：应用骨架
- [ ] 创建 `lib/app.dart`：配置 GoRouter（5 个路由）+ MaterialApp.router
- [ ] 创建 `lib/shared/widgets/main_scaffold.dart`：底部导航栏（首页、账单、记账、预算、图表）
- [ ] 创建各页面的空占位文件（home_page、transaction_list_page、budget_page、analytics_page、settings_page）
- [ ] 确保 `flutter run` 可以启动，底部导航可切换

### 任务 5：记账页（核心功能）
- [ ] 创建 `lib/shared/widgets/number_keyboard.dart`：自定义数字键盘（0-9、小数点、退格）
- [ ] 创建 `lib/shared/widgets/category_picker.dart`：分类网格选择器
- [ ] 实现收入/支出类型切换（Tab 或 SegmentedButton）
- [ ] 集成日期选择器（DatePicker）
- [ ] 集成备注输入框
- [ ] 组装 `lib/features/transaction/add/add_transaction_page.dart`
- [ ] 接入 `TransactionDao` 保存数据，保存后返回上页

### 任务 6：首页
- [ ] 创建月度汇总卡片（当月总收入 / 总支出 / 结余）
- [ ] 创建最近 5 条账单列表（含分类图标、金额、日期）
- [ ] 右下角 FAB 跳转记账页
- [ ] 使用 Riverpod `StreamProvider` 实现数据实时更新

### 任务 7：账单列表页
- [ ] 按日期分组显示所有账单（SliverList）
- [ ] 每日小计显示
- [ ] 滑动删除（Dismissible）
- [ ] 点击跳转编辑页（复用记账页，传入已有数据）
- [ ] 顶部月份切换（上个月 / 下个月）

---

## 第二阶段：预算与图表

### 任务 8：预算功能
- [ ] 创建 `lib/features/budget/budget_page.dart`
- [ ] 月总预算设置（输入框）
- [ ] 按分类设置预算（可选）
- [ ] 预算进度条组件：已用金额 / 总预算，超支时变红
- [ ] 使用 `BudgetDao` 读写数据

### 任务 9：图表分析页
- [ ] 创建 `lib/features/analytics/analytics_page.dart`
- [ ] **饼图**：当月支出按分类占比（fl_chart PieChart）
- [ ] **折线图**：近 6 个月收入/支出趋势（fl_chart LineChart）
- [ ] **柱状图**：当月每日支出金额（fl_chart BarChart）
- [ ] 顶部月份/年份切换器
- [ ] 图表点击显示详情（可选）

---

## 第三阶段：体验优化

### 任务 10：主题与计算器
- [ ] 创建 `lib/shared/theme/app_theme.dart`（亮色/暗色 ThemeData）
- [ ] 设置页加入主题切换开关
- [ ] 记账页数字键盘支持简单计算（+ - × ÷），显示计算式

### 任务 11：其他完善
- [ ] CSV 导出（按月导出到本地 Downloads）
- [ ] 空状态页面（首次使用无数据时的引导提示）
- [ ] 分类管理页（新增、删除自定义分类）

---

## 验证方式

每个阶段完成后：
1. `flutter run` 在 Android 模拟器或真机运行
2. 手动测试：添加账单 → 首页显示正确汇总
3. 第二阶段：添加预算 → 图表正确渲染
4. `flutter test` 运行单元测试（DAO 层）

---

## 建议开发顺序

```
任务 1（初始化）
  → 任务 2（数据库）
    → 任务 3（默认数据）
      → 任务 4（骨架）
        → 任务 5（记账页）
          → 任务 6（首页）
            → 任务 7（列表页）
              → 任务 8（预算）
                → 任务 9（图表）
                  → 任务 10-11（优化）
```

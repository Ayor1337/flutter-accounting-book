# 记账本

一款基于 Flutter 的个人记账应用，支持收支记录、预算管理与数据分析。

## 功能

- **记账**：快速录入收入/支出，支持分类、日期、备注
- **账单列表**：按日期分组浏览，支持编辑与滑动删除
- **首页汇总**：当月总收入、总支出、结余一览，展示最近账单
- **预算管理**：设置月总预算或按分类预算，进度条实时显示超支状态
- **图表分析**：饼图（分类占比）、折线图（近 6 个月趋势）、柱状图（每日支出）

## 技术栈

| 层次 | 选型 |
|------|------|
| 状态管理 | flutter_riverpod |
| 本地数据库 | Drift（SQLite ORM） |
| 路由 | go_router |
| 图表 | fl_chart |
| UI | Material 3 |

## 开发环境要求

- Flutter SDK `^3.11.1`
- Android `minSdk 21`

## 快速开始

```bash
# 安装依赖
flutter pub get

# 生成 Drift 数据库代码
dart run build_runner build --delete-conflicting-outputs

# 运行（连接 Android 设备或模拟器）
flutter run
```

## 常用命令

```bash
# 监听模式（修改表定义后自动重新生成）
dart run build_runner watch --delete-conflicting-outputs

# 运行测试
flutter test

# 代码格式化
dart format lib/

# 静态分析
flutter analyze
```

## 项目结构

```
lib/
├── main.dart
├── app.dart                  # 路由 + MaterialApp 配置
├── core/
│   ├── database/
│   │   ├── tables/           # Drift 表定义
│   │   ├── daos/             # 数据访问对象
│   │   ├── seeds/            # 默认分类数据
│   │   └── app_database.dart
│   ├── providers/            # Riverpod Provider
│   └── utils/
├── features/
│   ├── home/
│   ├── transaction/          # add/（记账页）、list/（账单列表）
│   ├── budget/
│   ├── analytics/
│   └── settings/
└── shared/
    ├── widgets/              # 数字键盘、分类选择器等公共组件
    └── theme/
```

> 详细开发计划见 [PLAN.md](PLAN.md)

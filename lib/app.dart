import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:accounting_book/shared/theme/app_theme.dart';
import 'package:accounting_book/shared/widgets/main_scaffold.dart';
import 'package:accounting_book/features/home/home_page.dart';
import 'package:accounting_book/features/transaction/list/transaction_list_page.dart';
import 'package:accounting_book/features/transaction/add/add_transaction_page.dart';
import 'package:accounting_book/features/budget/budget_page.dart';
import 'package:accounting_book/features/analytics/analytics_page.dart';
import 'package:accounting_book/features/settings/settings_page.dart';
import 'package:accounting_book/features/settings/category_management_page.dart';

/// 应用级主题状态，MaterialApp 会直接监听它来切换亮暗主题。
final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// 全局路由表。
/// 这里把底部导航的 5 个主页面放进 StatefulShellRoute，让每个 tab
/// 都保留自己的导航栈；设置页则作为独立页面压在外层。
final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionListPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/add',
            builder: (context, state) {
              // 复用同一个记账页处理“新增”和“编辑”两种场景。
              // 如果带有 transactionId，就进入编辑模式并回填旧数据。
              final id = state.uri.queryParameters['transactionId'];
              return AddTransactionPage(
                transactionId: id != null ? int.parse(id) : null,
              );
            },
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/budget',
            builder: (context, state) => const BudgetPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'categories',
          builder: (context, state) => const CategoryManagementPage(),
        ),
      ],
    ),
  ],
);

/// 应用根组件，负责把主题和路由装配进 MaterialApp。
class AccountingApp extends ConsumerWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: '记账本',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

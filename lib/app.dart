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

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

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
    ),
  ],
);

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

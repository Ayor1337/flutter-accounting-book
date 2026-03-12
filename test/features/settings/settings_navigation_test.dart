import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/features/home/home_page.dart';
import 'package:accounting_book/features/settings/settings_page.dart';
import 'package:accounting_book/shared/widgets/main_scaffold.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('settings opened from home can pop back to home', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final transactionDao = FakeHomeTransactionDao(database);
    late final GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDaoProvider.overrideWith((ref) => transactionDao),
        ],
        child: MaterialApp.router(
          routerConfig: router = _buildRouter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(router.canPop(), isTrue);

    router.pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}

class FakeHomeTransactionDao extends TransactionDao {
  FakeHomeTransactionDao(super.db);

  @override
  Stream<({double income, double expense})> getMonthlySummary(String month) {
    return Stream.value((income: 0.0, expense: 0.0));
  }

  @override
  Stream<List<Transaction>> getRecentTransactions(int limit) {
    return Stream.value(const []);
  }
}

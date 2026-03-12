import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/features/transaction/add/add_transaction_page.dart';
import 'package:accounting_book/shared/widgets/main_scaffold.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('AddTransactionPage', () {
    testWidgets('amount input does not rebuild the category section', (
      tester,
    ) async {
      await _setLargeSurface(tester);
      var categoryBuildCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AddTransactionPage(
              categoryPickerBuilder:
                  ({required type, required selectedId, required onSelected}) {
                    categoryBuildCount++;
                    return const SizedBox.shrink();
                  },
            ),
          ),
        ),
      );

      expect(categoryBuildCount, 1);

      await tester.tap(find.byKey(const Key('number-key-1')));
      await tester.pump();

      final amountText = tester.widget<Text>(
        find.byKey(const Key('amount-display')),
      );
      expect(amountText.data, '1');
      expect(categoryBuildCount, 1);
    });

    testWidgets('new entry resets amount after save when revisiting add page', (
      tester,
    ) async {
      await _setLargeSurface(tester);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final transactionDao = FakeTransactionDao(database);
      late final GoRouter router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionDaoProvider.overrideWith((ref) => transactionDao),
          ],
          child: MaterialApp.router(
            routerConfig: router = _buildRouter(
              addPageBuilder: () => AddTransactionPage(
                categoryPickerBuilder:
                    ({
                      required type,
                      required selectedId,
                      required onSelected,
                    }) {
                      return TextButton(
                        key: const Key('select-category'),
                        onPressed: () => onSelected(_expenseCategory),
                        child: const Text('select-category'),
                      );
                    },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('select-category')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('number-key-1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('number-key-confirm')));
      await tester.pumpAndSettle();

      expect(transactionDao.insertCallCount, 1);
      expect(find.text('transactions-page'), findsOneWidget);

      router.go('/add');
      await tester.pumpAndSettle();

      final amountText = tester.widget<Text>(
        find.byKey(const Key('amount-display')),
      );
      expect(amountText.data, '0');
    });
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

GoRouter _buildRouter({required Widget Function() addPageBuilder}) {
  return GoRouter(
    initialLocation: '/add',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            MainScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('transactions-page')),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                builder: (context, state) => addPageBuilder(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class FakeTransactionDao extends TransactionDao {
  FakeTransactionDao(super.db);

  int insertCallCount = 0;
  TransactionsCompanion? lastInserted;

  @override
  Future<int> insertTransaction(TransactionsCompanion transaction) async {
    insertCallCount++;
    lastInserted = transaction;
    return 1;
  }
}

const _expenseCategory = Category(
  id: 1,
  name: '餐饮',
  icon: 'restaurant',
  color: 0xFFFF5722,
  type: 'expense',
  isDefault: true,
);

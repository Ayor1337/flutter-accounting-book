import 'dart:async';

import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/utils/date_utils.dart';
import 'package:accounting_book/features/home/home_page.dart';
import 'package:accounting_book/features/home/widgets/monthly_summary_card.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps monthly summary card visible while switching months', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final month = currentMonth();
    final previous = previousMonth(month);
    final previousMonthController =
        StreamController<({double income, double expense})>.broadcast();
    addTearDown(previousMonthController.close);

    final transactionDao = FakeHomeTransactionDao(
      database,
      month: month,
      previousMonth: previous,
      previousMonthStream: previousMonthController.stream,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDaoProvider.overrideWith((ref) => transactionDao),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pump();

    expect(find.byType(MonthlySummaryCard), findsOneWidget);
    expect(find.text(formatMonth(month)), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump();

    expect(find.byType(MonthlySummaryCard), findsOneWidget);
    expect(find.text(formatMonth(previous)), findsOneWidget);
  });
}

class FakeHomeTransactionDao extends TransactionDao {
  FakeHomeTransactionDao(
    super.db, {
    required this.month,
    required this.previousMonth,
    required this.previousMonthStream,
  });

  final String month;
  final String previousMonth;
  final Stream<({double income, double expense})> previousMonthStream;

  @override
  Stream<({double income, double expense})> getMonthlySummary(String month) {
    if (month == this.month) {
      return Stream.value((income: 3000.0, expense: 1200.0));
    }

    if (month == previousMonth) {
      return previousMonthStream;
    }

    return Stream.value((income: 0.0, expense: 0.0));
  }

  @override
  Stream<List<Transaction>> getRecentTransactions(int limit) {
    return Stream.value(const []);
  }
}

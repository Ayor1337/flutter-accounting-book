import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/features/home/widgets/recent_transactions_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty state icon is horizontally centered', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: const Key('recent-records-viewport'),
              width: 360,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecentTransactionsList(transactions: <Transaction>[]),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final viewportCenter = tester.getCenter(
      find.byKey(const Key('recent-records-viewport')),
    );
    final iconCenter = tester.getCenter(
      find.byIcon(Icons.receipt_long_outlined),
    );

    expect(iconCenter.dx, moreOrLessEquals(viewportCenter.dx, epsilon: 1));
  });
}

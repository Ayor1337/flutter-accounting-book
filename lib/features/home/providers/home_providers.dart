import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

// 当前选中月份（首页用）
final homeMonthProvider = StateProvider<String>((ref) => currentMonth());

// 月度收支汇总
final monthlySummaryProvider = StreamProvider.autoDispose
    .family<({double income, double expense}), String>((ref, month) {
  return ref.watch(transactionDaoProvider).getMonthlySummary(month);
});

// 最近5条交易（不随月份变化）
final recentTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(transactionDaoProvider).getRecentTransactions(5);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

// 当前选中月份（首页用）
final homeMonthProvider = StateProvider<String>((ref) => currentMonth());

// 首页顶部汇总卡片的数据来源。
// 参数化的 family 让同一个 Provider 可以根据不同月份复用查询逻辑。
final monthlySummaryProvider = StreamProvider.autoDispose
    .family<({double income, double expense}), String>((ref, month) {
  return ref.watch(transactionDaoProvider).getMonthlySummary(month);
});

// 首页底部最近记录列表。它固定取最新 5 条，不受月份切换影响。
final recentTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(transactionDaoProvider).getRecentTransactions(5);
});

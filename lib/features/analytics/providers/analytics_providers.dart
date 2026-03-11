import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

// 当前分析月份
final analyticsMonthProvider = StateProvider<String>((ref) => currentMonth());

// 当月分类支出（饼图用）
final categoryExpenseProvider = FutureProvider.autoDispose
    .family<Map<int, double>, String>((ref, month) {
  return ref.watch(transactionDaoProvider).getMonthlyExpenseByCategory(month);
});

// 当月每日支出（柱状图用）
final dailyExpenseProvider = FutureProvider.autoDispose
    .family<Map<String, double>, String>((ref, month) {
  return ref.watch(transactionDaoProvider).getDailyExpense(month);
});

// 近6个月收支趋势（折线图用）
final monthlyTotalsProvider = FutureProvider.autoDispose
    .family<Map<String, ({double income, double expense})>, String>(
        (ref, month) {
  final months = <String>[];
  var m = month;
  for (var i = 0; i < 6; i++) {
    months.insert(0, m);
    m = previousMonth(m);
  }
  return ref.watch(transactionDaoProvider).getMonthlyTotals(months);
});

// 近6个月列表（用于折线图 x 轴标签）
final recentSixMonthsProvider = Provider.autoDispose.family<List<String>, String>((ref, month) {
  final months = <String>[];
  var m = month;
  for (var i = 0; i < 6; i++) {
    months.insert(0, m);
    m = previousMonth(m);
  }
  return months;
});

// 所有分类（饼图图例用）
final allCategoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoryDaoProvider).getAllCategories();
});

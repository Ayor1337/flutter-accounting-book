import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

/// 预算页当前月份
final budgetMonthProvider = StateProvider<String>((ref) => currentMonth());

/// 月总预算（categoryId IS NULL）
final monthlyBudgetProvider = FutureProvider.autoDispose
    .family<Budget?, String>((ref, month) {
  return ref.watch(budgetDaoProvider).getMonthlyBudget(month);
});

/// 分类预算列表（categoryId IS NOT NULL）
final categoryBudgetsProvider = FutureProvider.autoDispose
    .family<List<Budget>, String>((ref, month) {
  return ref.watch(budgetDaoProvider).getCategoryBudgets(month);
});

/// 当月各分类支出，键为 categoryId，值为支出金额
final monthlyExpenseProvider = FutureProvider.autoDispose
    .family<Map<int, double>, String>((ref, month) {
  return ref.watch(transactionDaoProvider).getMonthlyExpenseByCategory(month);
});

/// 所有分类，键为 categoryId，值为 Category 对象
final allCategoriesMapProvider = FutureProvider.autoDispose<Map<int, Category>>(
  (ref) async {
    final list = await ref.watch(categoryDaoProvider).getAllCategories();
    return {for (final c in list) c.id: c};
  },
);

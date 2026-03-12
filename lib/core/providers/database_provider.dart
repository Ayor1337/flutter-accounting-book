import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/database/daos/category_dao.dart';
import 'package:accounting_book/core/database/daos/budget_dao.dart';

/// 数据库单例 Provider。
/// 页面和其他 Provider 通过依赖它，共享同一个 AppDatabase 实例。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Riverpod 容器销毁时同步关闭数据库，避免文件句柄泄漏。
  ref.onDispose(() => db.close());
  return db;
});

/// 下面三个 Provider 只是把数据库里的 DAO 按职责暴露出去，
/// UI 层不需要自己关心 AppDatabase 的内部结构。
final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(appDatabaseProvider).transactionDao;
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return ref.watch(appDatabaseProvider).categoryDao;
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return ref.watch(appDatabaseProvider).budgetDao;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/database/daos/category_dao.dart';
import 'package:accounting_book/core/database/daos/budget_dao.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return ref.watch(appDatabaseProvider).transactionDao;
});

final categoryDaoProvider = Provider<CategoryDao>((ref) {
  return ref.watch(appDatabaseProvider).categoryDao;
});

final budgetDaoProvider = Provider<BudgetDao>((ref) {
  return ref.watch(appDatabaseProvider).budgetDao;
});

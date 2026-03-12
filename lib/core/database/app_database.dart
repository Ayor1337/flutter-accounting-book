import 'dart:io';

import 'package:accounting_book/core/database/daos/budget_dao.dart';
import 'package:accounting_book/core/database/daos/category_dao.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/database/tables/budgets.dart';
import 'package:accounting_book/core/database/tables/categories.dart';
import 'package:accounting_book/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, Categories, Budgets],
  daos: [TransactionDao, CategoryDao, BudgetDao],
)
/// Drift 数据库入口。
/// 这里集中声明表、DAO、迁移策略，以及应用启动时如何打开本地 SQLite。
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试时可注入内存数据库或自定义执行器，避免直接操作真实文件。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // 首次建库后马上写入默认分类，保证记账页一开始就有可选项。
      await categoryDao.seedDefaultCategories();
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // LazyDatabase 会在真正访问数据库时才建立连接，降低启动时的同步开销。
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'accounting.db'));
    return NativeDatabase.createInBackground(file);
  });
}

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
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await categoryDao.seedDefaultCategories();
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'accounting.db'));
    return NativeDatabase.createInBackground(file);
  });
}

import 'package:accounting_book/core/database/tables/categories.dart';
import 'package:drift/drift.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get month => text()();
  RealColumn get totalAmount => real()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {month, categoryId},
      ];
}

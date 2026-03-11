import 'package:accounting_book/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:accounting_book/core/database/tables/transactions.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<int> insertTransaction(TransactionsCompanion entry) {
    return into(transactions).insert(entry);
  }

  Future<bool> updateTransaction(TransactionsCompanion entry) {
    return (update(transactions)..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  Future<bool> deleteTransaction(TransactionsCompanion entry) {
    return (delete(
      transactions,
    )..where((t) => t.id.equals(entry.id.value))).go().then((rows) => rows > 0);
  }

  Stream<List<Transaction>> watchTransactionsByMonth(String month) {
    return (select(transactions)
          ..where((t) => t.date.year.equals(int.parse(month.split('-')[0])))
          ..where((t) => t.date.month.equals(int.parse(month.split('-')[1])))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }
}

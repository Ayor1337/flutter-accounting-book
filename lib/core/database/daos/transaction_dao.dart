import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/tables/categories.dart';
import 'package:accounting_book/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';

part 'transaction_dao.g.dart';

/// 联表查询结果：交易 + 所属分类
class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  TransactionWithCategory({
    required this.transaction,
    required this.category,
  });
}

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ──────────────────────────────────────────────────────────────────────────
  // 内部辅助：将 'YYYY-MM' 转换为起止 DateTime
  // ──────────────────────────────────────────────────────────────────────────
  static (DateTime start, DateTime end) _monthRange(String month) {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final mon = int.parse(parts[1]);
    final start = DateTime(year, mon, 1);
    // 下月第一天作为 exclusive 上限
    final end = DateTime(year, mon + 1, 1);
    return (start, end);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // a. 最近 N 条交易（按日期降序）
  // ──────────────────────────────────────────────────────────────────────────
  Stream<List<Transaction>> getRecentTransactions(int limit) {
    return (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .watch();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // b. 汇总某月收支总额
  // ──────────────────────────────────────────────────────────────────────────
  Stream<({double income, double expense})> getMonthlySummary(String month) {
    final (start, end) = _monthRange(month);

    final incomeExpr = transactions.amount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.type, incomeExpr])
      ..where(
        transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerThanValue(end),
      )
      ..groupBy([transactions.type]);

    return query.watch().map((rows) {
      double income = 0;
      double expense = 0;
      for (final row in rows) {
        final type = row.read(transactions.type);
        final amount = row.read(incomeExpr) ?? 0.0;
        if (type == 'income') {
          income = amount;
        } else {
          expense = amount;
        }
      }
      return (income: income, expense: expense);
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // c. JOIN categories，按日期降序，监听某月所有交易
  // ──────────────────────────────────────────────────────────────────────────
  Stream<List<TransactionWithCategory>> watchTransactionsWithCategoryByMonth(
    String month,
  ) {
    final (start, end) = _monthRange(month);

    final query = select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.categoryId)),
    ])
      ..where(
        transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerThanValue(end),
      )
      ..orderBy([OrderingTerm.desc(transactions.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          transaction: row.readTable(transactions),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // d. 当月支出按 categoryId 聚合
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<int, double>> getMonthlyExpenseByCategory(String month) async {
    final (start, end) = _monthRange(month);
    final amountSum = transactions.amount.sum();

    final query = selectOnly(transactions)
      ..addColumns([transactions.categoryId, amountSum])
      ..where(
        transactions.type.equals('expense') &
            transactions.date.isBiggerOrEqualValue(start) &
            transactions.date.isSmallerThanValue(end),
      )
      ..groupBy([transactions.categoryId]);

    final rows = await query.get();
    final result = <int, double>{};
    for (final row in rows) {
      final categoryId = row.read(transactions.categoryId);
      final total = row.read(amountSum) ?? 0.0;
      if (categoryId != null) {
        result[categoryId] = total;
      }
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // e. 当月每日支出（key 为 'YYYY-MM-DD' 字符串）
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, double>> getDailyExpense(String month) async {
    final (start, end) = _monthRange(month);

    // SQLite 中 Drift 将 DateTime 存为 Unix 时间戳（整数秒）或 ISO 字符串。
    // 使用 customSelect 以便直接用 strftime 格式化日期。
    final rows = await customSelect(
      'SELECT strftime(\'%Y-%m-%d\', date / 1000, \'unixepoch\') AS day, '
      'SUM(amount) AS total '
      'FROM "transactions" '
      'WHERE type = \'expense\' '
      '  AND date >= ? AND date < ? '
      'GROUP BY day',
      variables: [
        Variable<int>(start.millisecondsSinceEpoch),
        Variable<int>(end.millisecondsSinceEpoch),
      ],
      readsFrom: {transactions},
    ).get();

    final result = <String, double>{};
    for (final row in rows) {
      final day = row.read<String>('day');
      final total = (row.data['total'] as num).toDouble();
      result[day] = total;
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // f. 批量查询多个月份的收支合计
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, ({double income, double expense})>> getMonthlyTotals(
    List<String> months,
  ) async {
    if (months.isEmpty) return {};

    // 构建每个月的范围条件，用 strftime 提取 'YYYY-MM' 与目标列表比对
    final placeholders = months.map((_) => '?').join(', ');
    final rows = await customSelect(
      'SELECT strftime(\'%Y-%m\', date / 1000, \'unixepoch\') AS month_key, '
      'type, SUM(amount) AS total '
      'FROM "transactions" '
      'WHERE strftime(\'%Y-%m\', date / 1000, \'unixepoch\') IN ($placeholders) '
      'GROUP BY month_key, type',
      variables: months.map((m) => Variable<String>(m)).toList(),
      readsFrom: {transactions},
    ).get();

    final result = <String, ({double income, double expense})>{};
    for (final row in rows) {
      final monthKey = row.read<String>('month_key');
      final type = row.read<String>('type');
      final total = (row.data['total'] as num).toDouble();

      final existing = result[monthKey];
      if (type == 'income') {
        result[monthKey] = (
          income: total,
          expense: existing?.expense ?? 0.0,
        );
      } else {
        result[monthKey] = (
          income: existing?.income ?? 0.0,
          expense: total,
        );
      }
    }

    // 确保所有请求的月份都有条目（即使没有交易数据）
    for (final m in months) {
      result.putIfAbsent(m, () => (income: 0.0, expense: 0.0));
    }

    return result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 基础 CRUD
  // ──────────────────────────────────────────────────────────────────────────

  /// 插入一条交易记录
  Future<int> insertTransaction(TransactionsCompanion transaction) {
    return into(transactions).insert(transaction);
  }

  /// 更新一条交易记录
  Future<bool> updateTransaction(TransactionsCompanion transaction) {
    return update(transactions).replace(transaction);
  }

  /// 删除指定 id 的交易记录
  Future<void> deleteTransaction(int id) async {
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }
}

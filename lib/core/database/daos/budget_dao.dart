import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/tables/budgets.dart';
import 'package:drift/drift.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  /// 监听某月所有预算（响应式）
  Stream<List<Budget>> watchBudgetsByMonth(String month) {
    return (select(budgets)..where((t) => t.month.equals(month))).watch();
  }

  /// 新增或更新预算
  /// - 总预算（categoryId == null）：SQLite NULL != NULL，唯一约束不会触发冲突，
  ///   需先删除同月总预算行再插入，避免重复累积。
  /// - 分类预算：利用 (month, categoryId) 唯一约束做 upsert。
  Future<void> upsertBudget(BudgetsCompanion budget) async {
    if (budget.categoryId.value == null) {
      await (delete(budgets)
            ..where(
              (t) => t.month.equals(budget.month.value) & t.categoryId.isNull(),
            ))
          .go();
      await into(budgets).insert(budget);
    } else {
      await into(budgets).insertOnConflictUpdate(budget);
    }
  }

  /// 删除指定 id 的预算
  Future<void> deleteBudget(int id) async {
    await (delete(budgets)..where((t) => t.id.equals(id))).go();
  }

  /// 获取某月的总预算（category_id IS NULL）
  Future<Budget?> getMonthlyBudget(String month) {
    return (select(budgets)
          ..where((t) => t.month.equals(month) & t.categoryId.isNull()))
        .getSingleOrNull();
  }

  /// 获取某月所有分类预算（category_id IS NOT NULL）
  Future<List<Budget>> getCategoryBudgets(String month) {
    return (select(budgets)
          ..where((t) => t.month.equals(month) & t.categoryId.isNotNull()))
        .get();
  }
}

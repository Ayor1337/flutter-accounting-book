import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';
import 'package:accounting_book/core/utils/date_utils.dart';
import 'package:accounting_book/features/budget/providers/budget_providers.dart';
import 'package:accounting_book/features/budget/widgets/budget_edit_dialog.dart';
import 'package:accounting_book/features/budget/widgets/budget_progress_bar.dart';
import 'package:accounting_book/shared/widgets/category_picker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final monthlyBudgetAsync = ref.watch(monthlyBudgetProvider(month));
    final categoryBudgetsAsync = ref.watch(categoryBudgetsProvider(month));
    final monthlyExpenseAsync = ref.watch(monthlyExpenseProvider(month));
    final categoriesMapAsync = ref.watch(allCategoriesMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(budgetMonthProvider.notifier).state =
                    previousMonth(month);
              },
            ),
            Text(formatMonth(month)),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(budgetMonthProvider.notifier).state =
                    nextMonth(month);
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── 月总预算卡片 ────────────────────────────────────────────────
          Card(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('月总预算'),
                  subtitle: monthlyBudgetAsync.when(
                    data: (budget) => Text(
                      budget != null
                          ? '¥${formatAmount(budget.totalAmount)}'
                          : '未设置',
                    ),
                    loading: () => const Text('加载中…'),
                    error: (e, _) => const Text('加载失败'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: '编辑月总预算',
                    onPressed: () => _editMonthlyBudget(
                      context,
                      ref,
                      month,
                      monthlyBudgetAsync.valueOrNull,
                    ),
                  ),
                ),
                // 总进度条：已用 = 当月所有支出之和
                monthlyExpenseAsync.when(
                  data: (expenseMap) {
                    final totalUsed = expenseMap.values.fold(
                      0.0,
                      (a, b) => a + b,
                    );
                    final totalBudget =
                        monthlyBudgetAsync.valueOrNull?.totalAmount ?? 0.0;
                    return BudgetProgressBar(
                      label: '本月支出',
                      used: totalUsed,
                      total: totalBudget,
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── 分类预算标题行 ───────────────────────────────────────────────
          ListTile(
            title: const Text(
              '分类预算',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              tooltip: '添加分类预算',
              onPressed: () =>
                  _addCategoryBudget(context, ref, month, categoryBudgetsAsync.valueOrNull ?? []),
            ),
          ),

          // ── 分类预算列表 ─────────────────────────────────────────────────
          categoryBudgetsAsync.when(
            data: (budgetList) {
              if (budgetList.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      '暂无分类预算，点击右上角 + 添加',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: budgetList.map((budget) {
                  return _CategoryBudgetCard(
                    budget: budget,
                    month: month,
                    categoriesMapAsync: categoriesMapAsync,
                    monthlyExpenseAsync: monthlyExpenseAsync,
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('加载失败：$e'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 编辑月总预算 ──────────────────────────────────────────────────────────
  Future<void> _editMonthlyBudget(
    BuildContext context,
    WidgetRef ref,
    String month,
    Budget? current,
  ) async {
    await BudgetEditDialog.show(
      context,
      title: '编辑月总预算',
      initialAmount: current?.totalAmount ?? 0.0,
      onSave: (amount) async {
        await ref.read(budgetDaoProvider).upsertBudget(
          BudgetsCompanion(
            month: Value(month),
            totalAmount: Value(amount),
            categoryId: const Value(null),
          ),
        );
        ref.invalidate(monthlyBudgetProvider(month));
      },
    );
  }

  // ── 添加分类预算 ──────────────────────────────────────────────────────────
  Future<void> _addCategoryBudget(
    BuildContext context,
    WidgetRef ref,
    String month,
    List<Budget> existingBudgets,
  ) async {
    // 已有预算的分类 id 集合，用于过滤
    final existingCategoryIds =
        existingBudgets.map((b) => b.categoryId).whereType<int>().toSet();

    // Step 1：选择分类
    Category? selected;
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('选择支出分类'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: CategoryPicker(
                type: 'expense',
                onSelected: (category) {
                  selected = category;
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );

    if (selected == null) return;
    if (existingCategoryIds.contains(selected!.id)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「${selected!.name}」已有预算，请直接编辑')),
        );
      }
      return;
    }

    // Step 2：输入金额
    if (!context.mounted) return;
    final chosenCategory = selected!;
    await BudgetEditDialog.show(
      context,
      title: '设置「${chosenCategory.name}」预算',
      initialAmount: 0.0,
      onSave: (amount) async {
        await ref.read(budgetDaoProvider).upsertBudget(
          BudgetsCompanion(
            month: Value(month),
            totalAmount: Value(amount),
            categoryId: Value(chosenCategory.id),
          ),
        );
        ref.invalidate(categoryBudgetsProvider(month));
      },
    );
  }
}

// ── 单个分类预算卡片 ──────────────────────────────────────────────────────────
class _CategoryBudgetCard extends ConsumerWidget {
  final Budget budget;
  final String month;
  final AsyncValue<Map<int, Category>> categoriesMapAsync;
  final AsyncValue<Map<int, double>> monthlyExpenseAsync;

  const _CategoryBudgetCard({
    required this.budget,
    required this.month,
    required this.categoriesMapAsync,
    required this.monthlyExpenseAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryName = categoriesMapAsync.when(
      data: (map) =>
          budget.categoryId != null
              ? (map[budget.categoryId!]?.name ?? '未知分类')
              : '未知分类',
      loading: () => '加载中…',
      error: (e, _) => '未知分类',
    );

    final used = monthlyExpenseAsync.when(
      data: (map) =>
          budget.categoryId != null ? (map[budget.categoryId!] ?? 0.0) : 0.0,
      loading: () => 0.0,
      error: (e, _) => 0.0,
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(categoryName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: '编辑',
                  onPressed: () =>
                      _editCategoryBudget(context, ref, categoryName),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除',
                  onPressed: () => _deleteCategoryBudget(context, ref),
                ),
              ],
            ),
          ),
          BudgetProgressBar(
            label: categoryName,
            used: used,
            total: budget.totalAmount,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _editCategoryBudget(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
  ) async {
    await BudgetEditDialog.show(
      context,
      title: '编辑「$categoryName」预算',
      initialAmount: budget.totalAmount,
      onSave: (amount) async {
        await ref.read(budgetDaoProvider).upsertBudget(
          BudgetsCompanion(
            month: Value(month),
            totalAmount: Value(amount),
            categoryId: Value(budget.categoryId),
          ),
        );
        ref.invalidate(categoryBudgetsProvider(month));
      },
    );
  }

  Future<void> _deleteCategoryBudget(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除预算'),
        content: const Text('确定要删除该分类预算吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(budgetDaoProvider).deleteBudget(budget.id);
      ref.invalidate(categoryBudgetsProvider(month));
    }
  }
}

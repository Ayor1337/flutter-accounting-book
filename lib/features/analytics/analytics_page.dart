import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/utils/date_utils.dart';
import 'package:accounting_book/features/analytics/providers/analytics_providers.dart';
import 'package:accounting_book/features/analytics/widgets/category_pie_chart.dart';
import 'package:accounting_book/features/analytics/widgets/daily_expense_chart.dart';
import 'package:accounting_book/features/analytics/widgets/monthly_trend_chart.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(analyticsMonthProvider);
    final isCurrentMonth = month == currentMonth();

    final categoryExpenseAsync = ref.watch(categoryExpenseProvider(month));
    final dailyExpenseAsync = ref.watch(dailyExpenseProvider(month));
    final allCategoriesAsync = ref.watch(allCategoriesProvider);
    final sixMonths = ref.watch(recentSixMonthsProvider(month));
    // 折线图始终基于当前分析月份的近6月
    final monthlyTotalsAsync = ref.watch(monthlyTotalsProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(analyticsMonthProvider.notifier).state =
                    previousMonth(month);
              },
            ),
            GestureDetector(
              onTap: isCurrentMonth
                  ? null
                  : () {
                      ref.read(analyticsMonthProvider.notifier).state =
                          currentMonth();
                    },
              child: Text(
                formatMonth(month),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth
                    ? Theme.of(context).disabledColor
                    : null,
              ),
              onPressed: isCurrentMonth
                  ? null
                  : () {
                      ref.read(analyticsMonthProvider.notifier).state =
                          nextMonth(month);
                    },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 分类支出（饼图）──────────────────────────────────────
            _SectionHeader(title: '分类支出'),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: categoryExpenseAsync.when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 200,
                    child: Center(child: Text('加载失败：$e')),
                  ),
                  data: (expenseMap) => allCategoriesAsync.when(
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SizedBox(
                      height: 200,
                      child: Center(child: Text('加载失败：$e')),
                    ),
                    data: (categories) => CategoryPieChart(
                      expenseMap: expenseMap,
                      categories: categories,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── 每日支出（柱状图）──────────────────────────────────────
            _SectionHeader(title: '每日支出'),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                child: dailyExpenseAsync.when(
                  loading: () => const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 180,
                    child: Center(child: Text('加载失败：$e')),
                  ),
                  data: (dailyData) => DailyExpenseChart(
                    month: month,
                    dailyData: dailyData,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── 近6月趋势（折线图）──────────────────────────────────────
            _SectionHeader(title: '近6月趋势'),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
                child: monthlyTotalsAsync.when(
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 200,
                    child: Center(child: Text('加载失败：$e')),
                  ),
                  data: (totals) => MonthlyTrendChart(
                    months: sixMonths,
                    totals: totals,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:accounting_book/core/utils/date_utils.dart';
import 'package:accounting_book/features/home/providers/home_providers.dart';
import 'package:accounting_book/features/home/widgets/monthly_summary_card.dart';
import 'package:accounting_book/features/home/widgets/recent_transactions_list.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(homeMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider(month));
    final recentAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 月度收支卡片
            summaryAsync.when(
              loading: () => const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('加载失败：$e'),
                  ),
                ),
              ),
              data: (summary) => MonthlySummaryCard(
                month: month,
                summary: summary,
                onPreviousMonth: () {
                  ref.read(homeMonthProvider.notifier).state =
                      previousMonth(month);
                },
                onNextMonth: () {
                  ref.read(homeMonthProvider.notifier).state =
                      nextMonth(month);
                },
              ),
            ),

            // 最近记录标题
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '最近记录',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // 最近交易列表
            recentAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('加载失败：$e'),
              ),
              data: (transactions) =>
                  RecentTransactionsList(transactions: transactions),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add'),
        tooltip: '记账',
        child: const Icon(Icons.add),
      ),
    );
  }
}

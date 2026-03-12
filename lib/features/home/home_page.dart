import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:accounting_book/core/utils/date_utils.dart';
import 'package:accounting_book/features/home/providers/home_providers.dart';
import 'package:accounting_book/features/home/widgets/monthly_summary_card.dart';
import 'package:accounting_book/features/home/widgets/recent_transactions_list.dart';

/// 首页负责把“月份状态”“当月汇总”“最近记录”三条数据线组合成一个页面。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这三个 watch 可以视为首页的数据入口：
    // 1. 当前选中的月份
    // 2. 该月份的汇总流
    // 3. 全局最近 5 条记录
    final month = ref.watch(homeMonthProvider);
    final summaryAsync = ref.watch(monthlySummaryProvider(month));
    final recentAsync = ref.watch(recentTransactionsProvider);
    final summaryError =
        summaryAsync.hasError ? summaryAsync.error.toString() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 汇总卡片本身不直接处理 AsyncValue，而是由页面把加载/错误/数据
            // 三种状态拆开后传进去，卡片组件就能保持纯展示职责。
            MonthlySummaryCard(
              month: month,
              summary: summaryAsync.valueOrNull,
              isLoading: summaryAsync.isLoading,
              errorMessage: summaryError,
              onPreviousMonth: () {
                ref.read(homeMonthProvider.notifier).state = previousMonth(month);
              },
              onNextMonth: () {
                ref.read(homeMonthProvider.notifier).state = nextMonth(month);
              },
            ),

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

            // 最近记录继续保留 AsyncValue.when，让页面在这里完成状态分支。
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

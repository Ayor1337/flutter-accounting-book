import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/utils/date_utils.dart';
import 'package:accounting_book/features/transaction/list/providers/transaction_list_providers.dart';
import 'package:accounting_book/features/transaction/list/widgets/transaction_day_group.dart';

class TransactionListPage extends ConsumerWidget {
  const TransactionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(transactionListMonthProvider);
    final transactionsAsync = ref.watch(transactionsByMonthProvider(month));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(transactionListMonthProvider.notifier).state =
                    previousMonth(month);
              },
            ),
            Text(
              formatMonth(month),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(transactionListMonthProvider.notifier).state =
                    nextMonth(month);
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('加载失败：$err')),
        data: (transactions) => _buildBody(context, ref, transactions),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<TransactionWithCategory> transactions,
  ) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '本月暂无记录',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    // 按日期分组
    final grouped = <DateTime, List<TransactionWithCategory>>{};
    for (final twc in transactions) {
      final date = DateTime(
        twc.transaction.date.year,
        twc.transaction.date.month,
        twc.transaction.date.day,
      );
      grouped.putIfAbsent(date, () => []).add(twc);
    }

    // 按日期降序排列
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final transactionDao = ref.read(transactionDaoProvider);

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final group = grouped[date]!;
        return TransactionDayGroup(
          date: date,
          transactions: group,
          onDelete: (id) async {
            try {
              await transactionDao.deleteTransaction(id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('删除失败：$e')),
                );
              }
            }
          },
          onTap: (id) => context.push('/add?transactionId=$id'),
        );
      },
    );
  }
}

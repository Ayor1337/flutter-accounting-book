import 'package:flutter/material.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

/// 首页顶部卡片。
/// 它只负责展示，不直接发起查询，因此通过参数接收“数据 / 加载中 / 错误”
/// 三种状态。
class MonthlySummaryCard extends StatelessWidget {
  final String month;
  final ({double income, double expense})? summary;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const MonthlySummaryCard({
    super.key,
    required this.month,
    required this.summary,
    required this.isLoading,
    this.errorMessage,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.primary,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // 顶部：月份导航
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                  color: colorScheme.onPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  formatMonth(month),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                  color: colorScheme.onPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: _buildContent(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme) {
    if (summary != null) {
      final balance = summary!.income - summary!.expense;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '结余',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatAmount(balance),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: '收入',
                  amount: summary!.income,
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.greenAccent.shade200,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.onPrimary.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _SummaryItem(
                  label: '支出',
                  amount: summary!.expense,
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.redAccent.shade100,
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (isLoading) {
      // 固定高度内显示 loading，避免卡片在不同状态之间跳动。
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      // 错误信息收敛在卡片内部，首页布局不会因为异常而切成另一套结构。
      return Center(
        child: Text(
          '加载失败：$errorMessage',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onPrimary,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Center(
      child: Text(
        '暂无数据',
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onPrimary.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }
}

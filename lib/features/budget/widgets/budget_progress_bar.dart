import 'package:flutter/material.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';

class BudgetProgressBar extends StatelessWidget {
  final String label;
  final double used;
  final double total;

  const BudgetProgressBar({
    super.key,
    required this.label,
    required this.used,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOverBudget = total > 0 && used > total;
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final barColor = isOverBudget ? Colors.red : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  if (isOverBudget) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '超支',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                total > 0
                    ? '¥${formatAmount(used)} / ¥${formatAmount(total)}'
                    : '未设置',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOverBudget
                          ? Colors.red
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

const _iconMap = {
  'restaurant': Icons.restaurant,
  'directions_transit': Icons.directions_transit,
  'shopping_bag': Icons.shopping_bag,
  'home': Icons.home,
  'sports_esports': Icons.sports_esports,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'more_horiz': Icons.more_horiz,
  'work': Icons.work,
  'laptop_mac': Icons.laptop_mac,
  'trending_up': Icons.trending_up,
};

IconData _iconDataFor(String icon) {
  return _iconMap[icon] ?? Icons.category;
}

class TransactionDayGroup extends StatelessWidget {
  final DateTime date;
  final List<TransactionWithCategory> transactions;
  final Future<void> Function(int transactionId) onDelete;
  final void Function(int transactionId) onTap;

  const TransactionDayGroup({
    super.key,
    required this.date,
    required this.transactions,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 计算当日收支小计
    double dayIncome = 0;
    double dayExpense = 0;
    for (final twc in transactions) {
      if (twc.transaction.type == 'income') {
        dayIncome += twc.transaction.amount;
      } else {
        dayExpense += twc.transaction.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期行
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Text(
                formatDate(date),
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (dayExpense > 0)
                Text(
                  '支出 ${formatAmount(dayExpense)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.red.shade600,
                  ),
                ),
              if (dayExpense > 0 && dayIncome > 0)
                const SizedBox(width: 8),
              if (dayIncome > 0)
                Text(
                  '收入 ${formatAmount(dayIncome)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.green.shade600,
                  ),
                ),
            ],
          ),
        ),

        // 各条交易
        for (final twc in transactions)
          Dismissible(
            key: Key('transaction_${twc.transaction.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red.shade600,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) async => await onDelete(twc.transaction.id),
            child: _TransactionTile(twc: twc, onTap: onTap),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionWithCategory twc;
  final void Function(int transactionId) onTap;

  const _TransactionTile({required this.twc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryColor = Color(twc.category.color);
    final hasNote = twc.transaction.note != null &&
        twc.transaction.note!.trim().isNotEmpty;
    final isIncome = twc.transaction.type == 'income';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: categoryColor.withValues(alpha: 0.15),
        child: Icon(
          _iconDataFor(twc.category.icon),
          color: categoryColor,
          size: 20,
        ),
      ),
      title: Text(
        hasNote ? twc.transaction.note! : twc.category.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: hasNote
          ? Text(
              twc.category.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          : null,
      trailing: Text(
        formatAmountWithSign(twc.transaction.amount, twc.transaction.type),
        style: TextStyle(
          color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: () => onTap(twc.transaction.id),
    );
  }
}

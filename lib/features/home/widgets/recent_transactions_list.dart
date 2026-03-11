import 'package:flutter/material.dart';
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/utils/currency_formatter.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<Transaction> transactions;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              '暂无记录',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: transactions.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 56),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == 'income';
        final amountColor = isIncome ? Colors.green : Colors.red;
        final amountPrefix = isIncome ? '+' : '-';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isIncome ? Colors.green.shade50 : Colors.red.shade50,
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          title: Text(
            tx.note?.isNotEmpty == true ? tx.note! : (isIncome ? '收入' : '支出'),
            style: const TextStyle(fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            formatDate(tx.date),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Text(
            '$amountPrefix${formatAmount(tx.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        );
      },
    );
  }
}

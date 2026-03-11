import 'package:intl/intl.dart';

final _fmt = NumberFormat('#,##0.00');

String formatAmount(double amount) => _fmt.format(amount);

String formatAmountWithSign(double amount, String type) {
  final formatted = _fmt.format(amount);
  return type == 'income' ? '+$formatted' : '-$formatted';
}

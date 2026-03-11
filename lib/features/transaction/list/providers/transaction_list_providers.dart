import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

// 账单列表页当前月份
final transactionListMonthProvider =
    StateProvider<String>((ref) => currentMonth());

// 按月监听交易列表（含分类信息）
final transactionsByMonthProvider = StreamProvider.autoDispose
    .family<List<TransactionWithCategory>, String>((ref, month) {
  return ref
      .watch(transactionDaoProvider)
      .watchTransactionsWithCategoryByMonth(month);
});

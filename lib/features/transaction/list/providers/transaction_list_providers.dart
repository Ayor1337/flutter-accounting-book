import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/core/database/daos/transaction_dao.dart';
import 'package:accounting_book/core/utils/date_utils.dart';

// 账单列表页当前月份
final transactionListMonthProvider =
    StateProvider<String>((ref) => currentMonth());

// 账单页主数据源。
// DAO 已经把 transactions 和 categories 联表，页面拿到后可以直接渲染分类信息。
final transactionsByMonthProvider = StreamProvider.autoDispose
    .family<List<TransactionWithCategory>, String>((ref, month) {
  return ref
      .watch(transactionDaoProvider)
      .watchTransactionsWithCategoryByMonth(month);
});

import 'package:flutter/foundation.dart';

/// 记账页的金额输入控制器。
/// 它把“数字键盘输入规则”从页面状态里抽出来，页面只需要监听最终字符串。
class TransactionAmountController extends ValueNotifier<String> {
  TransactionAmountController([super.value = '0']);

  void input(String digit) {
    if (digit == '.') {
      // 金额只允许一个小数点。
      if (value.contains('.')) return;
      value = '$value.';
      return;
    }

    if (value.contains('.')) {
      // 保留两位小数，符合常见金额输入习惯。
      final decimalPart = value.split('.')[1];
      if (decimalPart.length >= 2) return;
    }

    value = value == '0' ? digit : '$value$digit';
  }

  void delete() {
    if (value.length <= 1) {
      value = '0';
      return;
    }
    value = value.substring(0, value.length - 1);
  }

  void reset() {
    value = '0';
  }

  void setAmount(String nextValue) {
    value = nextValue;
  }
}

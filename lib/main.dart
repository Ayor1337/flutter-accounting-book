import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/app.dart';

void main() {
  // ProviderScope 是 Riverpod 的根容器，后续所有 Provider 都从这里向下分发。
  runApp(const ProviderScope(child: AccountingApp()));
}

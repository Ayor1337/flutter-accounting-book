import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:accounting_book/app.dart';

void main() {
  runApp(const ProviderScope(child: AccountingApp()));
}

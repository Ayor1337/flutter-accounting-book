import 'package:flutter/material.dart';

class AddTransactionPage extends StatelessWidget {
  final int? transactionId;

  const AddTransactionPage({super.key, this.transactionId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('记账页')),
    );
  }
}

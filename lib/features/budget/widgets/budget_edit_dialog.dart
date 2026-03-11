import 'package:flutter/material.dart';

class BudgetEditDialog extends StatefulWidget {
  final String title;
  final double initialAmount;
  final void Function(double amount) onSave;

  const BudgetEditDialog({
    super.key,
    required this.title,
    required this.initialAmount,
    required this.onSave,
  });

  /// 便捷静态方法，直接弹出对话框
  static Future<void> show(
    BuildContext context, {
    required String title,
    required double initialAmount,
    required void Function(double) onSave,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BudgetEditDialog(
        title: title,
        initialAmount: initialAmount,
        onSave: onSave,
      ),
    );
  }

  @override
  State<BudgetEditDialog> createState() => _BudgetEditDialogState();
}

class _BudgetEditDialogState extends State<BudgetEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }
    Navigator.of(context).pop();
    widget.onSave(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          prefixText: '¥ ',
          hintText: '请输入金额',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

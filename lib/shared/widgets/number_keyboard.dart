import 'package:flutter/material.dart';

class NumberKeyboard extends StatelessWidget {
  final void Function(String digit) onInput;
  final VoidCallback onDelete;
  final VoidCallback onConfirm;

  const NumberKeyboard({
    super.key,
    required this.onInput,
    required this.onDelete,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 8),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 8),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKey(context, '.', onTap: () => onInput('.'))),
            const SizedBox(width: 8),
            Expanded(child: _buildKey(context, '0', onTap: () => onInput('0'))),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKey(
                context,
                null,
                icon: Icons.backspace_outlined,
                onTap: onDelete,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '确认',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      children: digits.asMap().entries.map((entry) {
        final index = entry.key;
        final digit = entry.value;
        return Expanded(
          child: Row(
            children: [
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: _buildKey(context, digit, onTap: () => onInput(digit)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKey(
    BuildContext context,
    String? label, {
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: icon != null
                ? Icon(icon, size: 22)
                : Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

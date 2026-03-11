import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/shared/widgets/category_picker.dart';
import 'package:accounting_book/shared/widgets/number_keyboard.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final int? transactionId;

  const AddTransactionPage({super.key, this.transactionId});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  String _selectedType = 'expense';
  String _amountStr = '0';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditMode => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadExistingTransaction();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTransaction() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final result = await (db.select(db.transactions)
            ..where((t) => t.id.equals(widget.transactionId!)))
          .getSingleOrNull();

      if (result != null && mounted) {
        // 加载对应分类
        final categoryDao = ref.read(categoryDaoProvider);
        final allCategories = await categoryDao.getAllCategories();
        final Category? category = allCategories.where((c) => c.id == result.categoryId).firstOrNull;

        setState(() {
          _selectedType = result.type;
          _amountStr = _formatAmountStr(result.amount);
          _selectedCategory = category;
          _selectedDate = result.date;
          _noteController.text = result.note ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAmountStr(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    // 去掉末尾多余的零
    return amount.toString().replaceAll(RegExp(r'0+$'), '');
  }

  void _onInput(String digit) {
    setState(() {
      if (digit == '.') {
        // 已有小数点则忽略
        if (_amountStr.contains('.')) return;
        // '0' 后面直接加小数点
        _amountStr = '$_amountStr.';
      } else {
        // 超过 2 位小数不允许继续输入
        if (_amountStr.contains('.')) {
          final decimalPart = _amountStr.split('.')[1];
          if (decimalPart.length >= 2) return;
        }
        if (_amountStr == '0') {
          _amountStr = digit;
        } else {
          _amountStr = '$_amountStr$digit';
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_amountStr.length <= 1) {
        _amountStr = '0';
      } else {
        _amountStr = _amountStr.substring(0, _amountStr.length - 1);
      }
    });
  }

  Future<void> _onConfirm() async {
    // 验证金额
    final amount = double.tryParse(_amountStr);
    if (amount == null || amount <= 0) {
      _showSnackBar('请输入有效金额');
      return;
    }

    // 验证分类
    if (_selectedCategory == null) {
      _showSnackBar('请选择分类');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final transactionDao = ref.read(transactionDaoProvider);

      final companion = TransactionsCompanion(
        id: _isEditMode ? Value(widget.transactionId!) : const Value.absent(),
        amount: Value(amount),
        type: Value(_selectedType),
        categoryId: Value(_selectedCategory!.id),
        note: Value(_noteController.text.isEmpty ? null : _noteController.text),
        date: Value(_selectedDate),
      );

      if (_isEditMode) {
        await transactionDao.updateTransaction(companion);
      } else {
        await transactionDao.insertTransaction(companion);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) _showSnackBar('保存失败：$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑记录' : '记账'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 收入/支出切换
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('支出')),
                      ButtonSegment(value: 'income', label: Text('收入')),
                    ],
                    selected: {_selectedType},
                    onSelectionChanged: (set) {
                      setState(() {
                        _selectedType = set.first;
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),

                // 金额显示区
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '¥',
                        style: TextStyle(
                          fontSize: 24,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _amountStr,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w300,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // 中间可滚动区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 分类选择器
                        CategoryPicker(
                          type: _selectedType,
                          selectedId: _selectedCategory?.id,
                          onSelected: (category) {
                            setState(() => _selectedCategory = category);
                          },
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // 日期选择
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('yyyy年MM月dd日').format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // 备注输入
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            hintText: '添加备注（可选）',
                            prefixIcon: Icon(
                              Icons.notes,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),

                // 底部固定数字键盘
                Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).padding.bottom + 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: NumberKeyboard(
                    onInput: _onInput,
                    onDelete: _onDelete,
                    onConfirm: _onConfirm,
                  ),
                ),
              ],
            ),
    );
  }
}

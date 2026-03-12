import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/features/transaction/add/transaction_amount_controller.dart';
import 'package:accounting_book/shared/widgets/category_picker.dart';
import 'package:accounting_book/shared/widgets/number_keyboard.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// 允许测试或调用方替换默认分类选择器，方便在不同场景下注入定制实现。
typedef CategoryPickerBuilder =
    Widget Function({
      required String type,
      required int? selectedId,
      required void Function(Category category) onSelected,
    });

/// 新增/编辑交易共用的页面。
/// 是否处于编辑模式由 `transactionId` 决定。
class AddTransactionPage extends ConsumerStatefulWidget {
  final int? transactionId;
  final CategoryPickerBuilder? categoryPickerBuilder;

  const AddTransactionPage({
    super.key,
    this.transactionId,
    this.categoryPickerBuilder,
  });

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  String _selectedType = 'expense';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  // 金额输入规则独立成控制器，页面只关心展示和提交。
  final TransactionAmountController _amountController =
      TransactionAmountController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditMode => widget.transactionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // 编辑模式需要先把已有记录读出来，再回填到表单控件。
      _loadExistingTransaction();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTransaction() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final result = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(widget.transactionId!))).getSingleOrNull();

      if (result != null && mounted) {
        final categoryDao = ref.read(categoryDaoProvider);
        final allCategories = await categoryDao.getAllCategories();
        final category = allCategories
            .where((c) => c.id == result.categoryId)
            .firstOrNull;

        _amountController.setAmount(_formatAmountStr(result.amount));
        setState(() {
          _selectedType = result.type;
          _selectedCategory = category;
          _selectedDate = result.date;
          _noteController.text = result.note ?? '';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatAmountStr(double amount) {
    if (amount == amount.truncateToDouble()) {
      return amount.toInt().toString();
    }
    // 编辑旧记录时，把 12.00 还原成更自然的显示形式 12。
    return amount.toString().replaceAll(RegExp(r'0+$'), '');
  }

  void _closePage() {
    if (!mounted) return;
    if (context.canPop()) {
      // 从列表页进入编辑时通常能直接 pop；独立打开时则回到账单页。
      context.pop();
      return;
    }
    context.go('/transactions');
  }

  void _resetNewEntryForm() {
    _amountController.reset();
    setState(() {
      _selectedCategory = null;
      _noteController.clear();
    });
  }

  Future<void> _onConfirm() async {
    final amount = double.tryParse(_amountController.value);
    if (amount == null || amount <= 0) {
      _showSnackBar('请输入有效金额');
      return;
    }

    if (_selectedCategory == null) {
      _showSnackBar('请选择分类');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final transactionDao = ref.read(transactionDaoProvider);

      // Drift 的 Companion 用来描述“本次准备写入哪些字段”。
      // 新增和编辑共用一套结构，差别只在 id 是否存在。
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
        if (mounted) {
          // 新增模式保存后先清空表单，便于连续记账。
          _resetNewEntryForm();
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('保存失败：$e');
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    _closePage();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  Widget _buildCategoryPicker() {
    final builder = widget.categoryPickerBuilder;
    if (builder != null) {
      // 自定义 builder 主要服务于测试或未来替换交互形式的场景。
      return builder(
        type: _selectedType,
        selectedId: _selectedCategory?.id,
        onSelected: (category) {
          setState(() => _selectedCategory = category);
        },
      );
    }

    return CategoryPicker(
      type: _selectedType,
      selectedId: _selectedCategory?.id,
      onSelected: (category) {
        setState(() => _selectedCategory = category);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑记录' : '记账'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closePage,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                        // 收支类型切换后，之前选中的分类可能不再有效，直接清空更安全。
                        _selectedCategory = null;
                      });
                    },
                  ),
                ),
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
                        child: ValueListenableBuilder<String>(
                          valueListenable: _amountController,
                          builder: (context, amount, _) {
                            return Text(
                              amount,
                              key: const Key('amount-display'),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 分类、日期、备注是业务字段；金额输入区单独固定在顶部。
                        _buildCategoryPicker(),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
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
                                  DateFormat(
                                    'yyyy年MM月dd日',
                                  ).format(_selectedDate),
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
                    onInput: _amountController.input,
                    onDelete: _amountController.delete,
                    onConfirm: _onConfirm,
                  ),
                ),
              ],
            ),
    );
  }
}

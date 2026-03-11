import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:accounting_book/shared/widgets/empty_state.dart';

// 预定义图标列表
const _availableIcons = [
  ('restaurant', Icons.restaurant),
  ('shopping_bag', Icons.shopping_bag),
  ('directions_transit', Icons.directions_transit),
  ('home', Icons.home),
  ('sports_esports', Icons.sports_esports),
  ('local_hospital', Icons.local_hospital),
  ('school', Icons.school),
  ('work', Icons.work),
  ('trending_up', Icons.trending_up),
  ('laptop_mac', Icons.laptop_mac),
  ('coffee', Icons.coffee),
  ('fitness_center', Icons.fitness_center),
  ('more_horiz', Icons.more_horiz),
];

// 预定义颜色列表
const _availableColors = [
  Color(0xFFFF5722),
  Color(0xFFF44336),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF2196F3),
  Color(0xFF00BCD4),
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFFFF9800),
  Color(0xFF795548),
  Color(0xFF607D8B),
  Color(0xFF9E9E9E),
];

/// 从图标名称字符串转换为 IconData
IconData _iconFromName(String name) {
  for (final (iconName, iconData) in _availableIcons) {
    if (iconName == name) return iconData;
  }
  return Icons.more_horiz;
}

class CategoryManagementPage extends ConsumerWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCategoryDialog(context, ref),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '支出'),
                Tab(text: '收入'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _CategoryList(type: 'expense'),
                  _CategoryList(type: 'income'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    String selectedType = 'expense';
    String selectedIcon = _availableIcons.first.$1;
    Color selectedColor = _availableColors.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加分类'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分类名称
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '分类名称',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 类型选择
                    const Text('类型', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'expense', label: Text('支出')),
                          ButtonSegment(value: 'income', label: Text('收入')),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (modes) {
                          setState(() => selectedType = modes.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 图标选择
                    const Text('图标', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableIcons.map((iconEntry) {
                        final (name, iconData) = iconEntry;
                        final isSelected = selectedIcon == name;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = name),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(iconData, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // 颜色选择
                    const Text('颜色', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => selectedColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(categoryDaoProvider).insertCategory(
                          CategoriesCompanion(
                            name: Value(name),
                            icon: Value(selectedIcon),
                            color: Value(selectedColor.toARGB32()),
                            type: Value(selectedType),
                            isDefault: const Value(false),
                          ),
                        );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }
}

class _CategoryList extends ConsumerWidget {
  final String type;

  const _CategoryList({required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesStream = ref.watch(categoryDaoProvider).watchCategoriesByType(type);

    return StreamBuilder<List<Category>>(
      stream: categoriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return EmptyState(
            message: '暂无${type == 'expense' ? '支出' : '收入'}分类',
            icon: Icons.category_outlined,
          );
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final iconData = _iconFromName(category.icon);
            final color = Color(category.color);

            return Dismissible(
              key: ValueKey(category.id),
              direction: category.isDefault
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              confirmDismiss: (_) async {
                return await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除分类'),
                    content: Text('确定要删除"${category.name}"吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                ref.read(categoryDaoProvider).deleteCategory(category.id);
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Icon(iconData, color: Colors.white, size: 20),
                ),
                title: Text(category.name),
                trailing: category.isDefault
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '内置',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('删除分类'),
                              content: Text('确定要删除"${category.name}"吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            ref.read(categoryDaoProvider).deleteCategory(category.id);
                          }
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

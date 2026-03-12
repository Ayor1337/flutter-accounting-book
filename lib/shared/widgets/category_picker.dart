import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _iconMap = {
  'restaurant': Icons.restaurant,
  'directions_transit': Icons.directions_transit,
  'shopping_bag': Icons.shopping_bag,
  'home': Icons.home,
  'sports_esports': Icons.sports_esports,
  'local_hospital': Icons.local_hospital,
  'school': Icons.school,
  'more_horiz': Icons.more_horiz,
  'work': Icons.work,
  'laptop_mac': Icons.laptop_mac,
  'trending_up': Icons.trending_up,
};

IconData _iconDataFor(String icon) {
  return _iconMap[icon] ?? Icons.category;
}

/// 分类选择器。
/// 它根据收入/支出类型监听不同分类列表，并把选中结果回传给父组件。
class CategoryPicker extends ConsumerStatefulWidget {
  final String type;
  final int? selectedId;
  final void Function(Category category) onSelected;

  const CategoryPicker({
    super.key,
    required this.type,
    required this.onSelected,
    this.selectedId,
  });

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  // 缓存当前类型对应的流，避免 build 时重复创建 Stream。
  late Stream<List<Category>> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = _watchCategories(widget.type);
  }

  @override
  void didUpdateWidget(covariant CategoryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      // 类型变化时切换到另一条分类流，例如“支出”切到“收入”。
      _categoriesStream = _watchCategories(widget.type);
    }
  }

  Stream<List<Category>> _watchCategories(String type) {
    final categoryDao = ref.read(categoryDaoProvider);
    return categoryDao.watchCategoriesByType(type);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Category>>(
      stream: _categoriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categoryList = snapshot.data ?? [];

        if (categoryList.isEmpty) {
          return const SizedBox(height: 80, child: Center(child: Text('暂无分类')));
        }

        // 这里用不可滚动 GridView，是为了把它嵌进父级滚动区域而不产生手势冲突。
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: categoryList.length,
          itemBuilder: (context, index) {
            final category = categoryList[index];
            final isSelected = category.id == widget.selectedId;
            final categoryColor = Color(category.color);

            return GestureDetector(
              onTap: () => widget.onSelected(category),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? categoryColor.withValues(alpha: 0.9)
                          : categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: categoryColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      _iconDataFor(category.icon),
                      color: isSelected ? Colors.white : categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

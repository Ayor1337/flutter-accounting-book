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

class CategoryPicker extends ConsumerWidget {
  final String type; // 'income' 或 'expense'
  final int? selectedId;
  final void Function(Category category) onSelected;

  const CategoryPicker({
    super.key,
    required this.type,
    required this.onSelected,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryDao = ref.watch(categoryDaoProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<Category>>(
      stream: categoryDao.watchCategoriesByType(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final categoryList = snapshot.data ?? [];

        if (categoryList.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('暂无分类')),
          );
        }

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
            final isSelected = category.id == selectedId;
            final categoryColor = Color(category.color);

            return GestureDetector(
              onTap: () => onSelected(category),
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

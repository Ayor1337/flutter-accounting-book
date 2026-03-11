import 'package:accounting_book/core/database/app_database.dart';
import 'package:drift/drift.dart';

final List<CategoriesCompanion> defaultCategories = [
  // 支出分类
  CategoriesCompanion.insert(
    name: '餐饮',
    icon: 'restaurant',
    color: 0xFFFF5722,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '交通',
    icon: 'directions_transit',
    color: 0xFF2196F3,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '购物',
    icon: 'shopping_bag',
    color: 0xFF9C27B0,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '住房',
    icon: 'home',
    color: 0xFF795548,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '娱乐',
    icon: 'sports_esports',
    color: 0xFF00BCD4,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '医疗',
    icon: 'local_hospital',
    color: 0xFFF44336,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '教育',
    icon: 'school',
    color: 0xFF4CAF50,
    type: 'expense',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '其他',
    icon: 'more_horiz',
    color: 0xFF9E9E9E,
    type: 'expense',
    isDefault: const Value(true),
  ),
  // 收入分类
  CategoriesCompanion.insert(
    name: '工资',
    icon: 'work',
    color: 0xFF4CAF50,
    type: 'income',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '兼职',
    icon: 'laptop_mac',
    color: 0xFF8BC34A,
    type: 'income',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '投资',
    icon: 'trending_up',
    color: 0xFF009688,
    type: 'income',
    isDefault: const Value(true),
  ),
  CategoriesCompanion.insert(
    name: '其他',
    icon: 'more_horiz',
    color: 0xFF607D8B,
    type: 'income',
    isDefault: const Value(true),
  ),
];

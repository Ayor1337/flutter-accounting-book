import 'package:accounting_book/core/database/app_database.dart';
import 'package:accounting_book/core/database/seeds/default_categories.dart';
import 'package:accounting_book/core/database/tables/categories.dart';
import 'package:drift/drift.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 按类型监听分类列表（响应式）
  Stream<List<Category>> watchCategoriesByType(String type) {
    return (select(categories)..where((t) => t.type.equals(type))).watch();
  }

  /// 获取所有分类
  Future<List<Category>> getAllCategories() {
    return select(categories).get();
  }

  /// 插入分类，返回新行 id
  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// 删除指定 id 的分类
  Future<void> deleteCategory(int id) async {
    await (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  /// 插入默认分类种子数据
  Future<void> seedDefaultCategories() async {
    await batch((batch) {
      batch.insertAll(categories, defaultCategories, mode: InsertMode.insertOrIgnore);
    });
  }
}

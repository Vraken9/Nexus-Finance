import 'package:isar/isar.dart';
import '../../core/utils/uuid_generator.dart';
import '../models/category_model.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// CategoryRepository
///
/// Manages [CategoryModel] CRUD plus seeding of default categories.
/// ─────────────────────────────────────────────────────────────────────────
class CategoryRepository {
  const CategoryRepository(this._isar);

  final Isar _isar;

  // ══ READ ═══════════════════════════════════════════════════════════════════

  List<CategoryModel> getAllForType(String type) =>
      _isar.categoryModels
          .filter()
          .typeEqualTo(type)
          .findAllSync();

  List<CategoryModel> getAll() =>
      _isar.categoryModels.where().findAllSync();

  CategoryModel? getByUuid(String uuid) =>
      _isar.categoryModels.filter().uuidEqualTo(uuid).findFirstSync();

  // ══ WRITE ══════════════════════════════════════════════════════════════════

  Future<void> createCategory(CategoryModel category) async =>
      _isar.writeTxn(() => _isar.categoryModels.put(category));

  /// Creates a custom category (not a default/seed category).
  /// Returns the UUID of the created category.
  Future<String> createCustomCategory({
    required String name,
    required String type, // 'income' | 'expense'
    required int iconCodePoint,
    required String colorHex,
  }) async {
    final uuid = UuidGenerator.generate();
    final category = CategoryModel()
      ..uuid = uuid
      ..name = name
      ..type = type
      ..iconCodePoint = iconCodePoint
      ..colorHex = colorHex
      ..isDefault = false;
    await _isar.writeTxn(() => _isar.categoryModels.put(category));
    return uuid;
  }

  Future<void> updateCategory(CategoryModel category) async =>
      _isar.writeTxn(() => _isar.categoryModels.put(category));

  /// Default categories cannot be deleted; returns false in that case.
  Future<bool> deleteCategory(String uuid) async {
    final cat = _isar.categoryModels.filter().uuidEqualTo(uuid).findFirstSync();
    if (cat == null || cat.isDefault) return false;
    await _isar.writeTxn(() => _isar.categoryModels.delete(cat.id));
    return true;
  }

  // ══ SEED DATA ══════════════════════════════════════════════════════════════

  Future<void> seedDefaultCategories() async {
    if (_isar.categoryModels.countSync() > 0) return;

    final defaults = <CategoryModel>[
      // ── Income ───────────────────────────────────────────────────────────
      CategoryModel()
        ..uuid = 'cat-salary'
        ..name = 'Salary'
        ..type = 'income'
        ..iconCodePoint = 0xe263 // Icons.work
        ..colorHex = '10B981'
        ..isDefault = true,
      CategoryModel()
        ..uuid = 'cat-freelance'
        ..name = 'Freelance'
        ..type = 'income'
        ..iconCodePoint = 0xe52f // Icons.laptop
        ..colorHex = '22C55E'
        ..isDefault = true,
      // ── Expense ──────────────────────────────────────────────────────────
      CategoryModel()
        ..uuid = 'cat-food'
        ..name = 'Food & Dining'
        ..type = 'expense'
        ..iconCodePoint = 0xe533 // Icons.restaurant
        ..colorHex = 'F43F5E'
        ..isDefault = true,
      CategoryModel()
        ..uuid = 'cat-transport'
        ..name = 'Transport'
        ..type = 'expense'
        ..iconCodePoint = 0xe531 // Icons.directions_car
        ..colorHex = 'F59E0B'
        ..isDefault = true,
      CategoryModel()
        ..uuid = 'cat-bills'
        ..name = 'Bills & Utilities'
        ..type = 'expense'
        ..iconCodePoint = 0xe3f7 // Icons.receipt
        ..colorHex = '0F172A'
        ..isDefault = true,
      CategoryModel()
        ..uuid = 'cat-shopping'
        ..name = 'Shopping'
        ..type = 'expense'
        ..iconCodePoint = 0xe59c // Icons.shopping_bag
        ..colorHex = '8B5CF6'
        ..isDefault = true,
      CategoryModel()
        ..uuid = 'cat-health'
        ..name = 'Health'
        ..type = 'expense'
        ..iconCodePoint = 0xe40d // Icons.favorite
        ..colorHex = 'EC4899'
        ..isDefault = true,
      CategoryModel()
        ..uuid = 'cat-entertainment'
        ..name = 'Entertainment'
        ..type = 'expense'
        ..iconCodePoint = 0xe01d // Icons.movie
        ..colorHex = '3B82F6'
        ..isDefault = true,
    ];

    await _isar.writeTxn(() async {
      for (final cat in defaults) {
        await _isar.categoryModels.put(cat);
      }
    });
  }
}

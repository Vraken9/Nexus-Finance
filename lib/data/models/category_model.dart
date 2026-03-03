import 'package:isar/isar.dart';

part 'category_model.g.dart';

/// ─────────────────────────────────────────────────────────────────
/// Category – groups transactions for analytics & budgeting.
///
/// [uuid]          : client-generated UUID stored in TransactionModel.categoryId
/// [iconCodePoint] : Material Icons codepoint
/// [colorHex]      : hex string e.g. "F43F5E" (no leading #)
/// ─────────────────────────────────────────────────────────────────
@collection
class CategoryModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value, unique: true)
  late String uuid;

  @Index(type: IndexType.value)
  late String name;

  /// 'income' | 'expense' — a category is either for income or expense.
  @Index(type: IndexType.value)
  late String type;

  int iconCodePoint = 0xe3af; // Icons.category

  late String colorHex; // e.g. "10B981"

  bool isDefault = false; // seed-data categories cannot be deleted

  @override
  String toString() =>
      'CategoryModel(uuid: $uuid, name: $name, type: $type)';
}

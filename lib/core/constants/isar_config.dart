import 'package:isar/isar.dart';
import '../../data/models/account_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/transaction_model.dart';

/// Single source of truth for the Isar schema collection list.
/// Import [isarSchemas] wherever you call [Isar.open].
const List<CollectionSchema<dynamic>> isarSchemas = [
  TransactionModelSchema,
  AccountModelSchema,
  CategoryModelSchema,
];

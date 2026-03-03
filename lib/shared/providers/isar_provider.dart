import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/isar_config.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// isarProvider
///
/// Exposes the singleton [Isar] instance to the entire Riverpod graph.
/// Guarded by [FutureProvider] so downstream widgets wait for the DB to open
/// before rendering.
///
/// Usage:
/// ```dart
/// final isar = ref.watch(isarProvider).requireValue;
/// ```
/// ─────────────────────────────────────────────────────────────────────────
final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    isarSchemas,
    directory: dir.path,
    name: 'nexus_finance_db',
  );
});

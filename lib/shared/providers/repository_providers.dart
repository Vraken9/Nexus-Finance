import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import 'isar_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Repository Providers
///
/// Each repository is a [Provider] that reads the [isarProvider].
/// Because they depend on an async provider they return an [AsyncValue] —
/// call .requireValue on the inner provider from a widget that is already
/// guarded by [isarProvider]'s loading/error state.
/// ─────────────────────────────────────────────────────────────────────────

/// Provides [TransactionRepository] once Isar is ready.
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return TransactionRepository(isar);
});

/// Provides [AccountRepository] once Isar is ready.
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return AccountRepository(isar);
});

/// Provides [CategoryRepository] once Isar is ready.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final isar = ref.watch(isarProvider).requireValue;
  return CategoryRepository(isar);
});

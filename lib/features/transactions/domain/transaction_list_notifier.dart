import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/transaction_model.dart';
import '../../../shared/providers/repository_providers.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// TransactionListNotifier
///
/// Manages pagination & filtering for the Transactions list screen.
///
/// State: AsyncValue<List<TransactionModel>>
/// ─────────────────────────────────────────────────────────────────────────
class TransactionListNotifier
    extends AutoDisposeAsyncNotifier<List<TransactionModel>> {
  int _page = 0;
  static const _pageSize = 20;

  @override
  Future<List<TransactionModel>> build() => _fetchPage(reset: true);

  // ── Public ─────────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    _page = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(reset: true));
  }

  Future<void> loadNextPage() async {
    if (state is AsyncLoading) return;
    final current = state.valueOrNull ?? [];
    _page++;
    final nextPage = await AsyncValue.guard(
      () => Future.value(
        ref.read(transactionRepositoryProvider).getPagedByDate(
              page: _page,
              pageSize: _pageSize,
            ),
      ),
    );
    state = nextPage.whenData((next) => [...current, ...next]);
  }

  Future<void> deleteTransaction(TransactionModel tx) async {
    await ref.read(transactionRepositoryProvider).deleteTransaction(tx);
    refresh();
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<List<TransactionModel>> _fetchPage({required bool reset}) {
    if (reset) _page = 0;
    return Future.value(
      ref.read(transactionRepositoryProvider).getPagedByDate(
            page: _page,
            pageSize: _pageSize,
          ),
    );
  }
}

final transactionListProvider =
    AutoDisposeAsyncNotifierProvider<TransactionListNotifier, List<TransactionModel>>(
  TransactionListNotifier.new,
);

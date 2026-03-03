import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';

/// Ensures dummy transactions for February 2026 are seeded once.
class DummySeedService {
  static bool _triggered = false;

  static Future<void> ensureFebruary2026(WidgetRef ref) async {
    if (_triggered) return;
    _triggered = true;
    await ref.read(transactionRepositoryProvider).seedFebruary2026Demo();
  }
}


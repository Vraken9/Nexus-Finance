import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Entry point for Nexus Finance.
///
/// Steps:
///  1. [WidgetsFlutterBinding.ensureInitialized] — required before any async
///     work in main.
///  2. [initializeDateFormatting] — initialises intl locale data for 'id_ID'
///     so that DateFormat / NumberFormat work correctly on all platforms.
///  3. [ProviderScope] — bootstraps the entire Riverpod dependency graph.
///  4. [NexusApp] waits for [isarProvider] before rendering feature screens.
///  5. Seed data (accounts + categories) is triggered lazily by repositories
///     on first read — no blocking at launch.
/// ─────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(
    const ProviderScope(
      child: NexusApp(),
    ),
  );
}


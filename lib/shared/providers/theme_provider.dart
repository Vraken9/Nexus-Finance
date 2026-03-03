import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// ThemeNotifier
///
/// Persists the user's preferred [ThemeMode] to a small file in the app's
/// documents directory.  Uses [path_provider] which is already a dependency.
///
/// Default: [ThemeMode.system].
/// ─────────────────────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _fileName = '.theme_mode';

  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.system;
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _loadSaved() async {
    try {
      final f = await _file();
      if (!f.existsSync()) return;
      final raw = await f.readAsString();
      final mode = ThemeMode.values.firstWhere(
        (m) => m.name == raw.trim(),
        orElse: () => ThemeMode.system,
      );
      state = mode;
    } catch (_) {
      // If anything fails, keep the default (system).
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final f = await _file();
      await f.writeAsString(mode.name);
    } catch (_) {}
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setThemeMode(next);
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);



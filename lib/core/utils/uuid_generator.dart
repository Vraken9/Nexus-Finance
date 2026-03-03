import 'dart:math';

/// UUID v4 generator using cryptographically random values.
abstract final class UuidGenerator {
  static final Random _random = Random.secure();

  /// Generates a UUID v4 string (36 chars: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx)
  static String generate() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));

    values[6] = (values[6] & 0x0f) | 0x40; // Version 4
    values[8] = (values[8] & 0x3f) | 0x80; // Variant 1

    return '${_toHex(values, 0, 4)}'
        '-${_toHex(values, 4, 6)}'
        '-${_toHex(values, 6, 8)}'
        '-${_toHex(values, 8, 10)}'
        '-${_toHex(values, 10, 16)}';
  }

  static String _toHex(List<int> values, int start, int end) {
    return values.sublist(start, end).map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  }
}

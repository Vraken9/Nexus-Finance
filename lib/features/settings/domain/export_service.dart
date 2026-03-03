import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/transaction_model.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// ExportService
///
/// Handles CSV export of transactions to the device /Documents directory
/// using Android Scoped Storage conventions.
///
/// Future extension: PDF export via the `pdf` package.
/// ─────────────────────────────────────────────────────────────────────────
class ExportService {
  const ExportService();

  // ── CSV ────────────────────────────────────────────────────────────────────

  /// Exports [transactions] for [month] as a CSV file.
  /// Returns the full path if successful; throws on failure.
  Future<String> exportCSV(
    List<TransactionModel> transactions,
    DateTime month,
  ) async {
    final csvContent = _buildCsv(transactions);
    final fileName = 'nexus_${DateHelpers.toMonthYear(month).replaceAll(' ', '_')}.csv';
    final file = await _resolveOutputFile(fileName);
    await file.writeAsString(csvContent);
    return file.path;
  }

  // ── Private ────────────────────────────────────────────────────────────────

  String _buildCsv(List<TransactionModel> transactions) {
    final buf = StringBuffer();
    // Header
    buf.writeln('Date,Type,Amount,CategoryId,AssetType,FromAccountId,ToAccountId,TransferFee,Note,AttachmentText');
    // Rows
    for (final tx in transactions) {
      buf.writeln([
        DateHelpers.toIso(tx.date),
        tx.type,
        CurrencyFormatter.formatPlain(tx.amount),
        tx.categoryId ?? '',
        tx.assetType ?? '',
        tx.fromAccountId ?? '',
        tx.toAccountId ?? '',
        tx.transferFee.toStringAsFixed(0),
        _escapeCsv(tx.note ?? ''),
        _escapeCsv(tx.attachmentText ?? ''),
      ].join(','));
    }
    return buf.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<File> _resolveOutputFile(String fileName) async {
    if (Platform.isAndroid) {
      // Scoped Storage: use the external Documents directory.
      final dir = Directory('/storage/emulated/0/Documents/NexusFinance');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return File('${dir.path}/$fileName');
    }
    // iOS / fallback: app documents directory.
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }
}

// `CsvExportUseCase` — writes the transactions of a date range to a CSV
// file the user saves through the system save dialog.
//
// Lives in `data/use_cases/` for the same reason as `CsvImportUseCase`:
// it reads three repositories and owns the file service call, so
// controllers never import `data/services/`. Never logs: rows carry memos
// and amounts.

import 'dart:isolate';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/transactions_csv.dart';
import '../models/category.dart';
import '../repositories/account_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/csv_file_service.dart';

class CsvExportUseCase {
  CsvExportUseCase({
    required this.fileService,
    required this.transactionRepo,
    required this.categoryRepo,
    required this.accountRepo,
  });

  final CsvFileService fileService;
  final TransactionRepository transactionRepo;
  final CategoryRepository categoryRepo;
  final AccountRepository accountRepo;

  /// Earliest and latest transaction date; null when there are none.
  Future<({DateTime first, DateTime last})?> getDateBounds() =>
      transactionRepo.getDateBounds();

  /// Exports every transaction dated on the local days [firstDay] through
  /// [lastDay] (times ignored) and shows the save dialog. Archived
  /// categories and accounts still resolve. [categoryName] localizes
  /// seeded category names.
  ///
  /// Returns the number of rows written, or null when the user cancels.
  /// Returns 0 without opening the dialog when the range is empty.
  Future<int?> export({
    required DateTime firstDay,
    required DateTime lastDay,
    required String Function(Category) categoryName,
  }) async {
    final start = DateHelpers.startOfDay(firstDay);
    final end = DateTime(lastDay.year, lastDay.month, lastDay.day + 1);
    final transactions = await transactionRepo.getInDateRange(start, end);
    if (transactions.isEmpty) return 0;
    // Read after the transactions: every category and account they use
    // exists by then, and used rows are archived, never deleted, so the
    // encoder's lookups always resolve.
    final (categories, accounts) = await (
      categoryRepo.watchAll(includeArchived: true).first,
      accountRepo.watchAll(includeArchived: true).first,
    ).wait;

    final categoriesById = <int, CsvExportCategory>{
      for (final c in categories) c.id: (name: categoryName(c), type: c.type),
    };
    final accountNames = {for (final a in accounts) a.id: a.name};
    // Encoding years of history can take longer than a frame.
    final bytes = await Isolate.run(
      () => encodeTransactionsCsv(
        transactions,
        categories: categoriesById,
        accountNames: accountNames,
      ),
    );

    final fileName =
        'ledgerly_transactions_${_day(firstDay)}_${_day(lastDay)}.csv';
    final saved = await fileService.save(fileName, bytes);
    return saved ? transactions.length : null;
  }
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

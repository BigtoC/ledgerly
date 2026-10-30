// CSV import screen state.
//
// Freezed sealed union driven by `CsvImportController`; the screen only
// renders it. Carries no memos or amounts: the rows themselves stay in
// the controller. See docs/superpowers/specs/2026-10-30-csv-import-design.md.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/category.dart';
import '../../../data/models/csv_import.dart';
import 'csv_import_matcher.dart';

part 'csv_import_state.freezed.dart';

@freezed
sealed class CsvImportState with _$CsvImportState {
  /// Before a file is picked.
  const factory CsvImportState.idle() = CsvImportIdle;

  /// Picking, parsing and matching a file.
  const factory CsvImportState.loading() = CsvImportLoading;

  /// The file is loaded; the user reviews it and resolves accounts.
  const factory CsvImportState.preview({
    required String fileName,

    /// Rows that will be inserted: valid and not already present.
    required int importCount,

    /// Recorded At range of those rows; null when [importCount] is 0.
    DateTime? firstRecordedAt,
    DateTime? lastRecordedAt,

    /// Skipped rows, sorted by line.
    required List<CsvRowError> errors,

    /// One entry per distinct CSV Account value among the rows to import.
    /// [CsvAccountMatch.resolution] is the current choice.
    required List<CsvAccountMatch> accounts,

    /// One entry per distinct CSV Category value among the rows to import.
    required List<CsvCategoryEntry> categories,
    required int duplicateCount,

    /// Every account is resolved and at least one row will be inserted.
    required bool canCommit,
  }) = CsvImportPreview;

  /// Writing the import; back navigation is blocked.
  const factory CsvImportState.committing() = CsvImportCommitting;

  /// The import was written. [invalidRowCount] comes from the load.
  const factory CsvImportState.done({
    required CsvImportResult result,
    required int invalidRowCount,
  }) = CsvImportDone;

  /// Nothing was imported. [missingColumns] is set for
  /// [CsvFileErrorKind.missingColumns].
  const factory CsvImportState.failure(
    CsvFileErrorKind kind, {
    @Default(<String>[]) List<String> missingColumns,
  }) = CsvImportFailure;
}

/// A preview row for one CSV Category value, with the categories its
/// resolution points at so the screen can label them.
@freezed
abstract class CsvCategoryEntry with _$CsvCategoryEntry {
  const CsvCategoryEntry._();

  const factory CsvCategoryEntry({
    required String csvValue,
    required int rowCount,
    required CategoryResolution resolution,

    /// The target of an `existing` resolution; null otherwise.
    Category? category,

    /// The income marker's targets: [salaryRowCount] rows go to
    /// [salaryCategory], the rest to [otherIncomeCategory]. Null otherwise.
    Category? salaryCategory,
    Category? otherIncomeCategory,
    @Default(0) int salaryRowCount,
  }) = _CsvCategoryEntry;

  bool get isNew => resolution is CreateCategoryResolution;

  int get otherIncomeRowCount => rowCount - salaryRowCount;

  CategoryType get type => switch (resolution) {
    CreateCategoryResolution(:final type) => type,
    IncomeByNoteCategoryResolution() => CategoryType.income,
    ExistingCategoryResolution() => category!.type,
  };
}

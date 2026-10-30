// CSV import controller.
//
// Drives Settings → Import from CSV: loads a file through
// `CsvImportUseCase`, matches it with `CsvImportMatcher`, holds the
// user's preview edits, then commits and refreshes exchange rates once.
// Not keepAlive: the screen scopes it. Never logs, because rows carry
// memos and amounts. See docs/superpowers/specs/2026-10-30-csv-import-design.md.

import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/default_currency_provider.dart';
import '../../../app/providers/repository_providers.dart';
import '../../../data/models/category.dart';
import '../../../data/models/csv_import.dart';
import '../../../l10n/app_localizations.dart';
import 'csv_import_matcher.dart';
import 'csv_import_state.dart';

part 'csv_import_controller.g.dart';

/// Labels of every supported locale, so matching never depends on the app
/// locale. Bare `zh` is left out because it resolves to English.
final _labelSets = [
  lookupAppLocalizations(const Locale('en')),
  lookupAppLocalizations(const Locale('zh', 'TW')),
  lookupAppLocalizations(const Locale('zh', 'CN')),
];

@Riverpod(
  dependencies: [
    csvImportUseCase,
    categoryRepository,
    accountRepository,
    accountTypeRepository,
    exchangeRateRepository,
    defaultCurrency,
    initialDefaultCurrency,
  ],
)
class CsvImportController extends _$CsvImportController {
  /// The loaded file; its valid rows become the commit plan.
  CsvLoadResult? _load;
  Set<String> _salaryNotes = const {};

  @override
  CsvImportState build() => const CsvImportState.idle();

  /// Opens the picker, then loads and matches the chosen file. A cancelled
  /// pick returns to idle.
  Future<void> pickFile() async {
    if (state is CsvImportLoading || state is CsvImportCommitting) return;
    final useCase = ref.read(csvImportUseCaseProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final accountTypeRepo = ref.read(accountTypeRepositoryProvider);
    final defaultCurrency = _defaultCurrency();
    state = const CsvImportState.loading();

    final CsvLoadResult? load;
    try {
      load = await useCase.pickAndLoad();
    } on CsvFileException catch (e) {
      if (ref.mounted) {
        state = CsvImportState.failure(
          e.kind,
          missingColumns: e.missingColumns,
        );
      }
      return;
    }
    if (!ref.mounted) return;
    if (load == null) {
      state = const CsvImportState.idle();
      return;
    }

    final (categories, accounts, accountTypes) = await (
      categoryRepo.watchAll(includeArchived: true).first,
      accountRepo.watchAll(includeArchived: true).first,
      accountTypeRepo.watchAll(includeArchived: true).first,
    ).wait;
    if (!ref.mounted) return;

    final match = CsvImportMatcher.resolve(
      rows: load.rowsToImport,
      categories: categories,
      accounts: accounts,
      accountTypes: accountTypes,
      labelSets: _labelSets,
      defaultCurrencyCode: defaultCurrency,
    );
    final categoriesById = {for (final c in categories) c.id: c};
    DateTime? first;
    DateTime? last;
    for (final row in load.rowsToImport) {
      if (first == null || row.recordedAt.isBefore(first)) {
        first = row.recordedAt;
      }
      if (last == null || row.recordedAt.isAfter(last)) last = row.recordedAt;
    }

    _load = load;
    _salaryNotes = match.salaryNotes;
    final importCount = load.rowsToImport.length;
    state = CsvImportState.preview(
      fileName: load.fileName,
      importCount: importCount,
      firstRecordedAt: first,
      lastRecordedAt: last,
      errors: load.errors,
      accounts: match.accounts,
      categories: [
        for (final m in match.categories) _categoryEntry(m, categoriesById),
      ],
      duplicateCount: load.duplicateCount,
      canCommit: _canCommit(importCount, match.accounts),
    );
  }

  /// Sets where the rows of the CSV Account value [csvValue] go.
  void setAccountResolution(String csvValue, AccountResolution resolution) {
    final s = state;
    if (s is! CsvImportPreview) return;
    final accounts = [
      for (final a in s.accounts)
        a.csvValue == csvValue ? a.copyWith(resolution: resolution) : a,
    ];
    state = s.copyWith(
      accounts: accounts,
      canCommit: _canCommit(s.importCount, accounts),
    );
  }

  /// Sets the type of the category that will be created for [csvValue].
  /// Ignored for values that match an existing category.
  void setNewCategoryType(String csvValue, CategoryType type) {
    final s = state;
    if (s is! CsvImportPreview) return;
    state = s.copyWith(
      categories: [
        for (final c in s.categories)
          if (c.resolution case final CreateCategoryResolution r
              when c.csvValue == csvValue)
            c.copyWith(resolution: r.copyWith(type: type))
          else
            c,
      ],
    );
  }

  /// Writes the import. Any failure rolls back and shows
  /// [CsvFileErrorKind.commitFailed].
  Future<void> commit() async {
    final s = state;
    final load = _load;
    if (s is! CsvImportPreview || !s.canCommit || load == null) return;
    final useCase = ref.read(csvImportUseCaseProvider);
    final rateRepo = ref.read(exchangeRateRepositoryProvider);
    final defaultCurrency = _defaultCurrency();
    state = const CsvImportState.committing();

    final CsvImportResult result;
    try {
      result = await useCase.commit(
        CsvImportPlan(
          rows: load.validRows,
          accounts: {for (final a in s.accounts) a.csvValue: a.resolution!},
          categories: {for (final c in s.categories) c.csvValue: c.resolution},
          salaryNotes: _salaryNotes,
        ),
      );
    } catch (_) {
      if (ref.mounted) {
        state = const CsvImportState.failure(CsvFileErrorKind.commitFailed);
      }
      return;
    }

    // One refresh covers every imported currency; never per row.
    if (result.currencyCodes.any((code) => code != defaultCurrency)) {
      unawaited(rateRepo.refreshAll(defaultCurrency));
    }
    if (!ref.mounted) return;
    state = CsvImportState.done(
      result: result,
      invalidRowCount: load.errors.length,
    );
  }

  /// Back to idle, dropping the loaded file.
  void reset() {
    _load = null;
    _salaryNotes = const {};
    state = const CsvImportState.idle();
  }

  String _defaultCurrency() =>
      ref.read(defaultCurrencyProvider).value ??
      ref.read(initialDefaultCurrencyProvider);
}

bool _canCommit(int importCount, List<CsvAccountMatch> accounts) =>
    importCount > 0 && accounts.every((a) => a.resolution != null);

CsvCategoryEntry _categoryEntry(
  CsvCategoryMatch match,
  Map<int, Category> categoriesById,
) {
  final entry = CsvCategoryEntry(
    csvValue: match.csvValue,
    rowCount: match.rowCount,
    resolution: match.resolution,
    salaryRowCount: match.salaryRowCount,
  );
  return switch (match.resolution) {
    ExistingCategoryResolution(:final categoryId) => entry.copyWith(
      category: categoriesById[categoryId],
    ),
    IncomeByNoteCategoryResolution(
      :final salaryCategoryId,
      :final otherCategoryId,
    ) =>
      entry.copyWith(
        salaryCategory: categoriesById[salaryCategoryId],
        otherIncomeCategory: categoriesById[otherCategoryId],
      ),
    CreateCategoryResolution() => entry,
  };
}

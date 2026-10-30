// Matches the Account and Category values of a Fortune City CSV import
// against existing rows and every locale's l10n labels.
//
// Pure: the controller passes in the rows to import, the domain lists
// (archived rows included) and one `AppLocalizations` per supported
// locale, so the result never depends on the app locale. Lives in
// features/ because label matching needs `AppLocalizations` and the
// `*_display.dart` key helpers; the data layer stays locale-free. See
// docs/superpowers/specs/2026-10-30-csv-import-design.md.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/csv_import_keys.dart';
import '../../../data/models/account.dart';
import '../../../data/models/account_type.dart';
import '../../../data/models/category.dart';
import '../../../data/models/csv_import.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/widgets/account_type_display.dart';
import '../../categories/widgets/category_display.dart';

part 'csv_import_matcher.freezed.dart';

/// How a CSV Account value matched. Tiers 1b, 2c and 3 need a decision.
enum CsvAccountTier {
  /// Tier 1: exactly one active account has this name.
  name,

  /// Tier 1b: several active accounts have this name.
  ambiguousName,

  /// Tier 2: the value is an account-type label and exactly one active
  /// account has that type.
  type,

  /// Tier 2b: the value is an account-type label and no active account
  /// has that type, so a new account of that type is proposed.
  typeWithoutAccount,

  /// Tier 2c: the value is an account-type label and several active
  /// accounts have that type.
  ambiguousType,

  /// Tier 3: nothing matched.
  none,
}

/// The match for one distinct CSV Account value.
@freezed
abstract class CsvAccountMatch with _$CsvAccountMatch {
  const CsvAccountMatch._();

  const factory CsvAccountMatch({
    required String csvValue,
    required int rowCount,
    required CsvAccountTier tier,

    /// The initial resolution; null when the user must decide.
    AccountResolution? resolution,

    /// The account type the value names (tiers 2, 2b, 2c); null otherwise.
    AccountType? matchedType,

    /// Currency of an account created for this value: the most frequent
    /// among its rows, a tie going to the default currency, then to the
    /// alphabetically first code.
    required String currencyCode,

    /// "Use an existing account" choices: every active account, then any
    /// archived account whose name normalizes to the value.
    required List<Account> options,
  }) = _CsvAccountMatch;

  bool get isNew =>
      resolution is CreateAccountResolution ||
      resolution is CreateTypeAndAccountResolution;

  /// Decision-sheet option 2, creating an account of [matchedType];
  /// null when no type matched.
  AccountResolution? get createAccountOption => switch (matchedType) {
    final type? => AccountResolution.createAccount(
      name: csvValue,
      accountTypeId: type.id,
      currencyCode: currencyCode,
    ),
    null => null,
  };

  /// Decision-sheet option 3, creating a type and an account; always
  /// offered.
  AccountResolution get createTypeAndAccountOption =>
      AccountResolution.createTypeAndAccount(
        name: csvValue,
        currencyCode: currencyCode,
      );
}

/// The match for one distinct CSV Category value.
@freezed
abstract class CsvCategoryMatch with _$CsvCategoryMatch {
  const CsvCategoryMatch._();

  const factory CsvCategoryMatch({
    required String csvValue,
    required int rowCount,
    required CategoryResolution resolution,

    /// For the income marker, how many rows have a Salary note; the
    /// other `rowCount - salaryRowCount` go to Other income. 0 otherwise.
    @Default(0) int salaryRowCount,
  }) = _CsvCategoryMatch;

  bool get isNew => resolution is CreateCategoryResolution;
}

/// Matcher output, in first-appearance order of the CSV values.
@freezed
abstract class CsvImportMatch with _$CsvImportMatch {
  const factory CsvImportMatch({
    required List<CsvAccountMatch> accounts,
    required List<CsvCategoryMatch> categories,

    /// The Salary label of every locale plus 薪资, for
    /// [CsvImportPlan.salaryNotes].
    required Set<String> salaryNotes,
  }) = _CsvImportMatch;
}

abstract final class CsvImportMatcher {
  /// Matches the Account and Category values of [rows] (the rows to
  /// import). [categories], [accounts] and [accountTypes] must include
  /// archived rows; [labelSets] holds one `AppLocalizations` per locale.
  static CsvImportMatch resolve({
    required List<CsvImportRow> rows,
    required List<Category> categories,
    required List<Account> accounts,
    required List<AccountType> accountTypes,
    required List<AppLocalizations> labelSets,
    required String defaultCurrencyCode,
  }) {
    final rowsByAccount = <String, List<CsvImportRow>>{};
    final rowsByCategory = <String, List<CsvImportRow>>{};
    for (final row in rows) {
      (rowsByAccount[row.account] ??= []).add(row);
      (rowsByCategory[row.category] ??= []).add(row);
    }

    // 薪资 is the Simplified form of 薪資; the zh_CN label is 工资.
    final salaryNotes = {
      for (final l in labelSets) l.categoryIncomeSalary,
      '薪资',
    };
    return CsvImportMatch(
      accounts: [
        for (final MapEntry(:key, :value) in rowsByAccount.entries)
          _matchAccount(
            key,
            value,
            accounts,
            accountTypes,
            labelSets,
            defaultCurrencyCode,
          ),
      ],
      categories: _matchCategories(
        rowsByCategory,
        categories,
        labelSets,
        salaryNotes.map(normalizeImportKey).toSet(),
      ),
      salaryNotes: salaryNotes,
    );
  }

  static CsvAccountMatch _matchAccount(
    String value,
    List<CsvImportRow> rows,
    List<Account> accounts,
    List<AccountType> accountTypes,
    List<AppLocalizations> labelSets,
    String defaultCurrencyCode,
  ) {
    final normalized = normalizeImportKey(value);
    final currencyCode = _accountCurrency(rows, defaultCurrencyCode);
    final active = accounts.where((a) => !a.isArchived).toList();
    final options = [
      ...active,
      ...accounts.where(
        (a) => a.isArchived && normalizeImportKey(a.name) == normalized,
      ),
    ];

    CsvAccountMatch entry(
      CsvAccountTier tier, {
      AccountResolution? resolution,
      AccountType? matchedType,
    }) => CsvAccountMatch(
      csvValue: value,
      rowCount: rows.length,
      tier: tier,
      resolution: resolution,
      matchedType: matchedType,
      currencyCode: currencyCode,
      options: options,
    );

    final byName = active
        .where((a) => normalizeImportKey(a.name) == normalized)
        .toList();
    if (byName.length == 1) {
      return entry(
        CsvAccountTier.name,
        resolution: AccountResolution.existing(byName.single.id),
      );
    }
    if (byName.length > 1) return entry(CsvAccountTier.ambiguousName);

    final types =
        accountTypes
            .where(
              (t) =>
                  !t.isArchived &&
                  _accountTypeLabels(t, labelSets).contains(normalized),
            )
            .toList()
          ..sort(
            (a, b) => _compareRank(
              (a.l10nKey != null, false, a.sortOrder, a.id),
              (b.l10nKey != null, false, b.sortOrder, b.id),
            ),
          );
    if (types.isEmpty) return entry(CsvAccountTier.none);

    final type = types.first;
    final ofType = active.where((a) => a.accountTypeId == type.id).toList();
    return switch (ofType.length) {
      0 => entry(
        CsvAccountTier.typeWithoutAccount,
        resolution: AccountResolution.createAccount(
          name: value,
          accountTypeId: type.id,
          currencyCode: currencyCode,
        ),
        matchedType: type,
      ),
      1 => entry(
        CsvAccountTier.type,
        resolution: AccountResolution.existing(ofType.single.id),
        matchedType: type,
      ),
      _ => entry(CsvAccountTier.ambiguousType, matchedType: type),
    };
  }

  static List<CsvCategoryMatch> _matchCategories(
    Map<String, List<CsvImportRow>> rowsByCategory,
    List<Category> categories,
    List<AppLocalizations> labelSets,
    Set<String> normalizedSalaryNotes,
  ) {
    final byLabel = <String, Set<Category>>{};
    for (final category in categories) {
      for (final label in _categoryLabels(category, labelSets)) {
        (byLabel[label] ??= {}).add(category);
      }
    }
    final incomeMarkers = {
      for (final l in labelSets) ...[
        normalizeImportKey(l.transactionTypeIncome),
        normalizeImportKey(l.categoriesSectionIncome),
      ],
    };

    return [
      for (final MapEntry(key: value, value: rows) in rowsByCategory.entries)
        if (incomeMarkers.contains(normalizeImportKey(value)))
          CsvCategoryMatch(
            csvValue: value,
            rowCount: rows.length,
            resolution: CategoryResolution.incomeByNote(
              salaryCategoryId: _seeded(categories, 'category.income.salary'),
              otherCategoryId: _seeded(categories, 'category.income.other'),
            ),
            salaryRowCount: rows
                .where((r) => isSalaryNote(r.memo, normalizedSalaryNotes))
                .length,
          )
        else
          CsvCategoryMatch(
            csvValue: value,
            rowCount: rows.length,
            resolution: _resolveCategory(value, byLabel),
          ),
    ];
  }

  static CategoryResolution _resolveCategory(
    String value,
    Map<String, Set<Category>> byLabel,
  ) {
    final candidates = byLabel[normalizeImportKey(value)];
    if (candidates == null) {
      return CategoryResolution.create(name: value, type: CategoryType.expense);
    }
    // Candidates in both types prefer expense: English "Investment" labels
    // both `category.investment` and `category.income.investment`.
    final expense = candidates.where((c) => c.type == CategoryType.expense);
    final ranked = (expense.isNotEmpty ? expense : candidates).toList()
      ..sort(
        (a, b) => _compareRank(
          (a.l10nKey != null, a.isArchived, a.sortOrder, a.id),
          (b.l10nKey != null, b.isArchived, b.sortOrder, b.id),
        ),
      );
    return CategoryResolution.existing(ranked.first.id);
  }

  static int _seeded(List<Category> categories, String l10nKey) =>
      categories.firstWhere((c) => c.l10nKey == l10nKey).id;

  static Set<String> _categoryLabels(
    Category category,
    List<AppLocalizations> labelSets,
  ) => _labels(
    category.customName,
    category.l10nKey,
    labelSets,
    categoryDisplayNameForKey,
  );

  static Set<String> _accountTypeLabels(
    AccountType type,
    List<AppLocalizations> labelSets,
  ) => _labels(
    type.customName,
    type.l10nKey,
    labelSets,
    accountTypeDisplayNameForKey,
  );

  /// Normalized [customName] plus the label of [l10nKey] in every label
  /// set. Unknown keys resolve to the key itself and are skipped.
  static Set<String> _labels(
    String? customName,
    String? l10nKey,
    List<AppLocalizations> labelSets,
    String Function(String, AppLocalizations) labelFor,
  ) => {
    if (customName != null && customName.trim().isNotEmpty)
      normalizeImportKey(customName),
    if (l10nKey != null)
      for (final l in labelSets)
        if (labelFor(l10nKey, l) case final label when label != l10nKey)
          normalizeImportKey(label),
  };

  static String _accountCurrency(
    List<CsvImportRow> rows,
    String defaultCurrencyCode,
  ) {
    final counts = <String, int>{};
    for (final row in rows) {
      counts[row.currency.code] = (counts[row.currency.code] ?? 0) + 1;
    }
    final most = counts.values.reduce((a, b) => a > b ? a : b);
    final tied = [
      for (final MapEntry(:key, :value) in counts.entries)
        if (value == most) key,
    ]..sort();
    return tied.contains(defaultCurrencyCode)
        ? defaultCurrencyCode
        : tied.first;
  }

  /// Tie-break: seeded first, then active before archived, then lowest
  /// sortOrder (null last), then lowest id.
  static int _compareRank(
    (bool seeded, bool archived, int? sortOrder, int id) a,
    (bool seeded, bool archived, int? sortOrder, int id) b,
  ) {
    if (a.$1 != b.$1) return a.$1 ? -1 : 1;
    if (a.$2 != b.$2) return a.$2 ? 1 : -1;
    if (a.$3 != b.$3) {
      if (a.$3 == null) return 1;
      if (b.$3 == null) return -1;
      return a.$3!.compareTo(b.$3!);
    }
    return a.$4.compareTo(b.$4);
  }
}

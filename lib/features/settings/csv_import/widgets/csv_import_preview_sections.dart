// CSV import preview pieces: the file summary, section headers, one tile
// per account and category entry, and the invalid-row lines. The screen
// lays them out in slivers. Value-in / callback-out; no providers.
//
// Invalid rows show only the line number and a localized reason, never
// field values, so the preview stays free of memos and amounts.

import 'package:flutter/material.dart';

import '../../../../core/utils/date_helpers.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/csv_import.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../accounts/widgets/account_type_display.dart';
import '../../../categories/widgets/category_display.dart';
import '../../../transactions/widgets/transaction_type_segmented_control.dart';
import '../csv_import_matcher.dart';
import '../csv_import_state.dart';

/// File name, rows to import, their date range and the balance note.
class CsvImportSummary extends StatelessWidget {
  const CsvImportSummary({super.key, required this.preview});

  final CsvImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final first = preview.firstRecordedAt;
    final last = preview.lastRecordedAt;
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(preview.fileName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.csvImportRowCount(preview.importCount)),
          if (first != null && last != null)
            Text(
              '${DateHelpers.formatDisplayDate(first, locale)} – '
              '${DateHelpers.formatDisplayDate(last, locale)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.csvImportBalanceNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CsvImportSectionHeader extends StatelessWidget {
  const CsvImportSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class CsvImportSubheader extends StatelessWidget {
  const CsvImportSubheader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One CSV Account value: its current resolution, or a prompt when the
/// user must decide. Tapping it opens the decision sheet.
class CsvAccountEntryTile extends StatelessWidget {
  const CsvAccountEntryTile({
    super.key,
    required this.match,
    required this.onTap,
  });

  final CsvAccountMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pending = match.resolution == null;
    final matchedByType = switch (match.resolution) {
      ExistingAccountResolution(:final accountId) =>
        match.tier == CsvAccountTier.type &&
            match.options.any(
              (a) =>
                  a.id == accountId && a.accountTypeId == match.matchedType?.id,
            ),
      _ => false,
    };
    return ListTile(
      leading: Icon(
        pending ? Icons.help_outline : Icons.check_circle_outline,
        color: pending ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: _TitleWithBadge(text: match.csvValue, isNew: match.isNew),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _resolutionLabel(match, l10n),
            style: pending ? TextStyle(color: theme.colorScheme.error) : null,
          ),
          if (matchedByType) Text(l10n.csvImportAccountMatchedByType),
          Text(l10n.csvImportRowCount(match.rowCount)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

String _resolutionLabel(CsvAccountMatch match, AppLocalizations l10n) =>
    switch (match.resolution) {
      null => l10n.csvImportAccountNeedsChoice,
      ExistingAccountResolution(:final accountId) => _existingAccountLabel(
        match,
        accountId,
        l10n,
      ),
      CreateAccountResolution(:final name) => l10n.csvImportAccountCreate(
        name,
        accountTypeDisplayName(match.matchedType!, l10n),
      ),
      CreateTypeAndAccountResolution(:final name) =>
        l10n.csvImportAccountCreateWithType(name),
    };

String _existingAccountLabel(
  CsvAccountMatch match,
  int accountId,
  AppLocalizations l10n,
) {
  for (final account in match.options) {
    if (account.id != accountId) continue;
    return account.isArchived
        ? l10n.csvImportAccountArchived(account.name)
        : account.name;
  }
  return '';
}

/// A CSV Category value that resolves to existing categories: one target,
/// or the income marker's Salary / Other income split.
class CsvExistingCategoryTile extends StatelessWidget {
  const CsvExistingCategoryTile({super.key, required this.entry});

  final CsvCategoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String line(Category? category, int count) =>
        '${category == null ? '' : categoryDisplayName(category, l10n)}'
        ' · ${l10n.csvImportRowCount(count)}';
    return ListTile(
      leading: Icon(
        Icons.check_circle_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(entry.csvValue),
      subtitle: switch (entry.resolution) {
        IncomeByNoteCategoryResolution() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line(entry.salaryCategory, entry.salaryRowCount)),
            Text(line(entry.otherIncomeCategory, entry.otherIncomeRowCount)),
          ],
        ),
        _ => Text(line(entry.category, entry.rowCount)),
      },
    );
  }
}

/// A CSV Category value that becomes a new custom category, with its
/// Expense/Income toggle.
class CsvNewCategoryTile extends StatelessWidget {
  const CsvNewCategoryTile({
    super.key,
    required this.entry,
    required this.onTypeChanged,
  });

  final CsvCategoryEntry entry;
  final ValueChanged<CategoryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: _TitleWithBadge(text: entry.csvValue, isNew: true),
          subtitle: Text(l10n.csvImportRowCount(entry.rowCount)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TransactionTypeSegmentedControl(
            key: ValueKey('csvImportCategoryType:${entry.csvValue}'),
            value: entry.type,
            onChanged: onTypeChanged,
          ),
        ),
      ],
    );
  }
}

/// One skipped row: line number and reason only.
class CsvRowErrorLine extends StatelessWidget {
  const CsvRowErrorLine({super.key, required this.error});

  final CsvRowError error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        l10n.csvImportRowErrorLine(error.lineNumber, _reason(error, l10n)),
      ),
    );
  }
}

String _reason(CsvRowError error, AppLocalizations l10n) =>
    switch (error.reason) {
      CsvRowErrorReason.columnCount => l10n.csvImportReasonColumnCount,
      CsvRowErrorReason.emptyAccount => l10n.csvImportReasonEmptyAccount,
      CsvRowErrorReason.emptyCategory => l10n.csvImportReasonEmptyCategory,
      CsvRowErrorReason.invalidAmount => l10n.csvImportReasonInvalidAmount,
      CsvRowErrorReason.zeroAmount => l10n.csvImportReasonZeroAmount,
      CsvRowErrorReason.unknownCurrency => l10n.csvImportReasonUnknownCurrency(
        error.currencyCode ?? '',
      ),
      CsvRowErrorReason.invalidDate => l10n.csvImportReasonInvalidDate,
    };

/// The value, followed by a New badge when a row will be created. A
/// `Wrap` so the badge drops to its own line at 2x text scale.
class _TitleWithBadge extends StatelessWidget {
  const _TitleWithBadge({required this.text, required this.isNew});

  final String text;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    if (!isNew) return Text(text);
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(text),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              AppLocalizations.of(context).csvImportNewBadge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

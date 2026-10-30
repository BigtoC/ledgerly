// Settings → Import from CSV.
//
// Pure projection of `csvImportControllerProvider`: renders each
// `CsvImportState` and forwards taps; every state change happens in the
// controller. The preview is a `CustomScrollView` whose lists use
// `SliverList.builder`. Back navigation is blocked while committing. See
// docs/superpowers/specs/2026-10-30-csv-import-design.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../data/models/csv_import.dart';
import '../../../l10n/app_localizations.dart';
import 'csv_import_controller.dart';
import 'csv_import_state.dart';
import 'widgets/csv_account_resolution_sheet.dart';
import 'widgets/csv_import_preview_sections.dart';

@Dependencies([CsvImportController])
class CsvImportScreen extends ConsumerWidget {
  const CsvImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(csvImportControllerProvider);
    final controller = ref.read(csvImportControllerProvider.notifier);
    return PopScope(
      canPop: state is! CsvImportCommitting,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.csvImportTitle)),
        body: switch (state) {
          CsvImportIdle() => _Message(
            lines: [l10n.csvImportIntro, l10n.csvImportPrivacyNote],
            actionLabel: l10n.csvImportChooseFile,
            onAction: controller.pickFile,
          ),
          CsvImportLoading() => _Progress(label: l10n.csvImportReading),
          final CsvImportPreview preview => _PreviewBody(
            preview: preview,
            controller: controller,
          ),
          CsvImportCommitting() => _Progress(label: l10n.csvImportImporting),
          CsvImportDone(:final result, :final invalidRowCount) => _Message(
            title: l10n.csvImportDoneTitle,
            lines: [
              l10n.csvImportDoneImported(result.importedCount),
              l10n.csvImportDoneSkipped(result.duplicateCount, invalidRowCount),
              l10n.csvImportDoneCreated(
                result.createdAccountCount,
                result.createdCategoryCount,
              ),
            ],
            actionLabel: l10n.csvImportDone,
            onAction: () => Navigator.of(context).pop(),
          ),
          final CsvImportFailure failure => _Message(
            lines: [_failureMessage(failure, l10n)],
            actionLabel: l10n.csvImportChooseAnother,
            onAction: controller.pickFile,
          ),
        },
        bottomNavigationBar: switch (state) {
          final CsvImportPreview preview => _ConfirmBar(
            preview: preview,
            onConfirm: controller.commit,
          ),
          _ => null,
        },
      ),
    );
  }
}

String _failureMessage(CsvImportFailure failure, AppLocalizations l10n) =>
    switch (failure.kind) {
      CsvFileErrorKind.tooLarge => l10n.csvImportErrorTooLarge,
      CsvFileErrorKind.notUtf8 => l10n.csvImportErrorNotUtf8,
      CsvFileErrorKind.empty => l10n.csvImportErrorEmpty,
      CsvFileErrorKind.missingColumns => l10n.csvImportErrorMissingColumns(
        failure.missingColumns.join(', '),
      ),
      CsvFileErrorKind.tooManyRows => l10n.csvImportErrorTooManyRows(
        kCsvImportMaxRows,
      ),
      CsvFileErrorKind.parse => l10n.csvImportErrorParse,
      CsvFileErrorKind.readFailed => l10n.csvImportErrorRead,
      CsvFileErrorKind.commitFailed => l10n.csvImportErrorCommit,
    };

class _Progress extends StatelessWidget {
  const _Progress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Idle, done and failure: a few lines of text and one button.
class _Message extends StatelessWidget {
  const _Message({
    this.title,
    required this.lines,
    required this.actionLabel,
    required this.onAction,
  });

  final String? title;
  final List<String> lines;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (title case final title?)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(line, style: theme.textTheme.bodyLarge),
          ),
        const SizedBox(height: 12),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _PreviewBody extends StatefulWidget {
  const _PreviewBody({required this.preview, required this.controller});

  final CsvImportPreview preview;
  final CsvImportController controller;

  @override
  State<_PreviewBody> createState() => _PreviewBodyState();
}

class _PreviewBodyState extends State<_PreviewBody> {
  bool _showErrors = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = widget.preview;
    final controller = widget.controller;
    final existing = [
      for (final c in preview.categories)
        if (!c.isNew) c,
    ];
    final created = [
      for (final c in preview.categories)
        if (c.isNew) c,
    ];
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: CsvImportSummary(preview: preview)),
        if (preview.accounts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: CsvImportSectionHeader(title: l10n.csvImportSectionAccounts),
          ),
          SliverList.builder(
            itemCount: preview.accounts.length,
            itemBuilder: (context, i) {
              final match = preview.accounts[i];
              return CsvAccountEntryTile(
                key: ValueKey('csvImportAccount:${match.csvValue}'),
                match: match,
                onTap: () async {
                  final chosen = await showCsvAccountResolutionSheet(
                    context,
                    match,
                  );
                  if (chosen != null) {
                    controller.setAccountResolution(match.csvValue, chosen);
                  }
                },
              );
            },
          ),
        ],
        if (preview.categories.isNotEmpty)
          SliverToBoxAdapter(
            child: CsvImportSectionHeader(
              title: l10n.csvImportSectionCategories,
            ),
          ),
        if (existing.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: CsvImportSubheader(title: l10n.csvImportCategoriesExisting),
          ),
          SliverList.builder(
            itemCount: existing.length,
            itemBuilder: (context, i) => CsvExistingCategoryTile(
              key: ValueKey('csvImportCategory:${existing[i].csvValue}'),
              entry: existing[i],
            ),
          ),
        ],
        if (created.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: CsvImportSubheader(title: l10n.csvImportCategoriesNew),
          ),
          SliverList.builder(
            itemCount: created.length,
            itemBuilder: (context, i) {
              final entry = created[i];
              return CsvNewCategoryTile(
                key: ValueKey('csvImportCategory:${entry.csvValue}'),
                entry: entry,
                onTypeChanged: (type) =>
                    controller.setNewCategoryType(entry.csvValue, type),
              );
            },
          ),
        ],
        if (preview.duplicateCount > 0 || preview.errors.isNotEmpty)
          SliverToBoxAdapter(
            child: CsvImportSectionHeader(title: l10n.csvImportSectionSkipped),
          ),
        if (preview.duplicateCount > 0)
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: Text(l10n.csvImportDuplicates(preview.duplicateCount)),
            ),
          ),
        if (preview.errors.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: ListTile(
              key: const ValueKey('csvImportInvalidRowsToggle'),
              leading: const Icon(Icons.error_outline),
              title: Text(l10n.csvImportInvalidRows(preview.errors.length)),
              trailing: Icon(
                _showErrors ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () => setState(() => _showErrors = !_showErrors),
            ),
          ),
          if (_showErrors)
            SliverList.builder(
              itemCount: preview.errors.length,
              itemBuilder: (context, i) =>
                  CsvRowErrorLine(error: preview.errors[i]),
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.preview, required this.onConfirm});

  final CsvImportPreview preview;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton(
          key: const ValueKey('csvImportConfirmButton'),
          onPressed: preview.canCommit ? onConfirm : null,
          child: Text(
            preview.importCount == 0
                ? l10n.csvImportNothingToImport
                : l10n.csvImportConfirm(preview.importCount),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

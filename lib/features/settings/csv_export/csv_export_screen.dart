// Settings → Export data.
//
// Pure projection of `csvExportControllerProvider`: shows the date range
// (every transaction by default), opens the range picker and forwards the
// export tap. The save dialog itself is the system's.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../core/utils/date_helpers.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import 'csv_export_controller.dart';
import 'csv_export_state.dart';

@Dependencies([CsvExportController])
class CsvExportScreen extends ConsumerWidget {
  const CsvExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(csvExportControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.csvExportTitle)),
      body: switch (state) {
        AsyncData(value: CsvExportEmpty()) => _Body(
          children: [Text(l10n.csvExportEmpty)],
        ),
        AsyncData(value: final CsvExportReady ready) => _ReadyBody(
          state: ready,
          controller: ref.read(csvExportControllerProvider.notifier),
        ),
        AsyncError() => _Body(children: [Text(l10n.errorSnackbarGeneric)]),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state, required this.controller});

  final CsvExportReady state;
  final CsvExportController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final exporting = state.status == CsvExportStatus.exporting;
    final isFullRange =
        state.rangeStart == state.firstDay && state.rangeEnd == state.lastDay;
    final message = switch (state.status) {
      CsvExportStatus.done => l10n.csvExportDone(state.exportedCount ?? 0),
      CsvExportStatus.failed => l10n.csvExportFailed,
      _ => null,
    };
    return _Body(
      children: [
        Text(l10n.csvExportIntro, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 12),
        Text(l10n.csvExportPrivacyNote, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        ListTile(
          key: const ValueKey('csvExportRangeTile'),
          contentPadding: EdgeInsets.zero,
          enabled: !exporting,
          title: Text(l10n.csvExportRange),
          subtitle: Text(
            '${DateHelpers.formatDisplayDate(state.rangeStart, locale)} – '
            '${DateHelpers.formatDisplayDate(state.rangeEnd, locale)}',
          ),
          trailing: const Icon(Icons.date_range),
          onTap: () => _pickRange(context),
        ),
        if (!isFullRange)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: exporting
                  ? null
                  : () => controller.setRange(state.firstDay, state.lastDay),
              child: Text(l10n.csvExportFullRange),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('csvExportButton'),
          onPressed: exporting
              ? null
              : () => controller.export((c) => categoryDisplayName(c, l10n)),
          child: exporting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.csvExportButton),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(message, style: theme.textTheme.bodyLarge),
          ),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: state.firstDay,
      lastDate: state.lastDay,
      initialDateRange: DateTimeRange(
        start: state.rangeStart,
        end: state.rangeEnd,
      ),
    );
    if (range != null) controller.setRange(range.start, range.end);
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(24), children: children);
  }
}

// CSV export controller.
//
// Drives Settings → Export data: loads the transaction date bounds as the
// default (full) range, holds the user's range, then runs
// `CsvExportUseCase`. Not keepAlive: the screen scopes it. Never logs,
// because the export carries memos and amounts.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/category.dart';
import 'csv_export_state.dart';

part 'csv_export_controller.g.dart';

@Riverpod(dependencies: [csvExportUseCase])
class CsvExportController extends _$CsvExportController {
  @override
  Future<CsvExportState> build() async {
    final bounds = await ref.watch(csvExportUseCaseProvider).getDateBounds();
    if (bounds == null) return const CsvExportState.empty();
    final first = DateHelpers.startOfDay(bounds.first);
    final last = DateHelpers.startOfDay(bounds.last);
    return CsvExportState.ready(
      firstDay: first,
      lastDay: last,
      rangeStart: first,
      rangeEnd: last,
    );
  }

  /// Sets the range to the days of [start] through [end].
  void setRange(DateTime start, DateTime end) {
    final s = state.value;
    if (s is! CsvExportReady || s.status == CsvExportStatus.exporting) return;
    state = AsyncData(
      s.copyWith(
        rangeStart: DateHelpers.startOfDay(start),
        rangeEnd: DateHelpers.startOfDay(end),
        status: CsvExportStatus.idle,
        exportedCount: null,
      ),
    );
  }

  /// Exports the range and opens the save dialog. A cancelled save returns
  /// to idle; an empty range reports [CsvExportStatus.noTransactions]
  /// without a dialog. [categoryName] localizes seeded category names.
  Future<void> export(String Function(Category) categoryName) async {
    final s = state.value;
    if (s is! CsvExportReady || s.status == CsvExportStatus.exporting) return;
    final useCase = ref.read(csvExportUseCaseProvider);
    state = AsyncData(
      s.copyWith(status: CsvExportStatus.exporting, exportedCount: null),
    );

    final int? count;
    try {
      count = await useCase.export(
        firstDay: s.rangeStart,
        lastDay: s.rangeEnd,
        categoryName: categoryName,
      );
    } catch (_) {
      if (ref.mounted) {
        state = AsyncData(
          s.copyWith(status: CsvExportStatus.failed, exportedCount: null),
        );
      }
      return;
    }
    if (!ref.mounted) return;
    state = AsyncData(switch (count) {
      null => s.copyWith(status: CsvExportStatus.idle, exportedCount: null),
      0 => s.copyWith(
        status: CsvExportStatus.noTransactions,
        exportedCount: null,
      ),
      _ => s.copyWith(status: CsvExportStatus.done, exportedCount: count),
    });
  }
}

// Detail-screen controller — see spec § Detail Screen State & Controller.

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../data/models/transaction.dart';
import 'analysis_controller.dart';
import 'analysis_state.dart';
import 'category_search_detail_state.dart';

part 'category_search_detail_controller.g.dart';

@Riverpod(
  keepAlive: true,
  dependencies: [transactionRepository, AnalysisController],
)
class CategorySearchDetailController extends _$CategorySearchDetailController {
  @override
  Stream<CategorySearchDetailState> build({
    required int categoryId,
    required String query,
    required String currencyCode,
  }) {
    final trimmed = query.trim();
    final trimmedCurrencyCode = currencyCode.trim();
    if (trimmed.isEmpty || trimmedCurrencyCode.isEmpty) {
      return Stream.value(const CategorySearchDetailState.empty());
    }

    if (ref.exists(analysisControllerProvider)) {
      final state = ref.read(analysisControllerProvider).valueOrNull;
      final matchesSettledQuery = switch (state) {
        AnalysisResults(:final query) => query == trimmed,
        AnalysisEmpty(:final query) => query == trimmed,
        _ => false,
      };

      if (matchesSettledQuery) {
        final all = ref
            .read(analysisControllerProvider.notifier)
            .lastTransactions;
        if (all != null) {
          return Stream.value(
            _buildState(
              all: all,
              categoryId: categoryId,
              currencyCode: trimmedCurrencyCode,
            ),
          );
        }
      }
    }

    final repo = ref.watch(transactionRepositoryProvider);
    return repo
        .watchByMemo(trimmed)
        .map(
          (all) => _buildState(
            all: all,
            categoryId: categoryId,
            currencyCode: trimmedCurrencyCode,
          ),
        );
  }

  CategorySearchDetailState _buildState({
    required List<Transaction> all,
    required int categoryId,
    required String currencyCode,
  }) {
    final filtered = all
        .where(
          (t) => t.categoryId == categoryId && t.currency.code == currencyCode,
        )
        .toList();

    if (filtered.isEmpty) {
      return const CategorySearchDetailState.empty();
    }

    final byDay = <DateTime, List<Transaction>>{};
    for (final tx in filtered) {
      final day = DateHelpers.startOfDay(tx.date);
      byDay.putIfAbsent(day, () => <Transaction>[]).add(tx);
    }

    final days =
        byDay.entries
            .map(
              (e) => DatedTransactionGroup(
                date: e.key,
                transactions: e.value,
                daySumMinorUnits: e.value.fold<int>(
                  0,
                  (sum, t) => sum + t.amountMinorUnits,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final overall = days.fold<int>(0, (sum, day) => sum + day.daySumMinorUnits);
    return CategorySearchDetailState.data(
      days: days,
      overallSumMinorUnits: overall,
      currency: filtered.first.currency,
    );
  }
}

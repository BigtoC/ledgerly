// Analysis-search state — see
// `docs/superpowers/specs/2026-05-09-transaction-search-design.md`
// § State & Controller.
//
// `AnalysisLoading.previous` carries the prior `AnalysisResults` payload
// so the UI can keep rendering the previous list under a spinner overlay
// while a new query debounces; `null` on the first search.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/category.dart';
import '../../../data/models/currency.dart';

part 'analysis_state.freezed.dart';

@freezed
sealed class AnalysisState with _$AnalysisState {
  /// No query typed yet — renders the search-prompt placeholder.
  const factory AnalysisState.idle() = AnalysisIdle;

  /// Query is debouncing or the underlying stream is re-subscribing.
  const factory AnalysisState.loading({
    required String query,
    List<CategorySearchResult>? previous,
  }) = AnalysisLoading;

  /// Query has matching transactions. Categories sorted by most-recent
  /// matching transaction date (descending), tiebreak `categoryId` asc.
  const factory AnalysisState.results({
    required List<CategorySearchResult> categories,
    required String query,
  }) = AnalysisResults;

  /// Query typed but no matching transactions.
  const factory AnalysisState.empty({required String query}) = AnalysisEmpty;
}

@freezed
abstract class CategorySearchResult with _$CategorySearchResult {
  const factory CategorySearchResult({
    /// Full category value object — widget resolves display via
    /// `categoryDisplayName(category, l10n)` (matches `TransactionTile`).
    required Category category,
    required int transactionCount,
    required int totalAmountMinorUnits,
    required Currency currency,

    /// `max(transaction.date)` within this `(category, currency)` group;
    /// primary sort key in `AnalysisResults`.
    required DateTime mostRecentDate,
  }) = _CategorySearchResult;
}

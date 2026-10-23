// Drill-down items list — sibling of `_ChartBody` inside `ChartsSection`'s
// Column. Renders nothing when no slice is selected, otherwise shows a
// header (label + transaction count + total + optional stale-rate notice)
// followed by `TransactionSearchRow` instances in action-only delete
// mode. Owns its own snackbar undo wiring via `SliceDrilldownController`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../core/constants.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/models/account.dart';
import '../../../../data/models/category.dart';
import '../../../../data/models/currency.dart';
import '../../../../data/models/transaction.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../categories/widgets/category_display.dart';
import '../../search/analysis_providers.dart';
import '../../search/widgets/transaction_search_row.dart';
import '../charts_providers.dart';
import '../charts_selection_controller.dart';
import '../charts_state.dart';
import '../selected_slice.dart';
import '../slice_drilldown_controller.dart';

/// Number of drill-down rows rendered per "Show N more" step. The rows sit
/// in a non-lazy `Column`, so this bounds the build/layout cost when a
/// slice holds hundreds of transactions.
const int _kDrilldownPageSize = 50;

@Dependencies([
  SliceDrilldownController,
  ChartsSelectionController,
  analysisCategoriesById,
  analysisAccountsById,
  chartsCurrenciesByCode,
  chartsFxStatus,
])
class SelectedSliceItemsList extends ConsumerStatefulWidget {
  const SelectedSliceItemsList({
    super.key,
    required this.slice,
    required this.locale,
  });

  /// The currently-selected chart slice (looked up by `selectionKey` in
  /// the parent so the list header total stays in lockstep with the pie
  /// slice's labeled amount).
  final ChartSlice slice;
  final String locale;

  @override
  ConsumerState<SelectedSliceItemsList> createState() =>
      _SelectedSliceItemsListState();
}

class _SelectedSliceItemsListState
    extends ConsumerState<SelectedSliceItemsList> {
  int? _lastShownPendingDeleteId;
  late final SliceDrilldownController _controller;
  ScaffoldMessengerState? _messenger;
  int _visibleCount = _kDrilldownPageSize;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(sliceDrilldownControllerProvider.notifier);
    _controller.setEffectListener(_onEffect);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
  }

  @override
  void didUpdateWidget(SelectedSliceItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent does not key this widget, so State survives slice changes.
    if (oldWidget.slice.selectionKey != widget.slice.selectionKey) {
      _visibleCount = _kDrilldownPageSize;
    }
  }

  @override
  void dispose() {
    _messenger?.clearSnackBars();
    _controller.setEffectListener(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref
        .watch(chartsSelectionControllerProvider)
        .selectedSlice;
    if (selection == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sliceDrilldownControllerProvider);
    final categoriesById =
        ref.watch(analysisCategoriesByIdProvider).value ?? const {};
    final accountsById =
        ref.watch(analysisAccountsByIdProvider).value ?? const {};
    final currenciesByCode =
        ref.watch(chartsCurrenciesByCodeProvider).value ?? const {};
    final fxStatus = ref.watch(chartsFxStatusProvider).value;

    ref.listen(sliceDrilldownControllerProvider, (_, next) {
      final pendingId = next.value?.pendingDeleteId;
      if (pendingId == null) {
        if (!next.hasValue) {
          _messenger?.clearSnackBars();
        }
        _lastShownPendingDeleteId = null;
        return;
      }
      if (_lastShownPendingDeleteId == pendingId) return;
      _lastShownPendingDeleteId = pendingId;
      _messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.homeDeleteUndoSnackbar),
            duration: kUndoWindow,
            action: SnackBarAction(
              label: l10n.commonUndo,
              onPressed: _controller.undoDelete,
            ),
          ),
        );
    });

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text(l10n.analysisErrorMessage)),
        ),
        data: (data) => SlidableAutoCloseBehavior(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ListHeader(
                label: _labelFor(
                  selection: selection,
                  slice: widget.slice,
                  categoriesById: categoriesById,
                  accountsById: accountsById,
                  l10n: l10n,
                ),
                count: data.rows.length,
                totalMinorUnits: widget.slice.totalMinorUnits,
                currencyCode: widget.slice.currencyCode,
                currenciesByCode: currenciesByCode,
                locale: widget.locale,
                l10n: l10n,
                showStaleRates: _showStaleRates(
                  fxStatus: fxStatus,
                  rows: data.rows,
                  slice: widget.slice,
                ),
              ),
              if (data.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text(l10n.analysisDrilldownEmpty)),
                )
              else
                for (final tx in data.rows.take(_visibleCount))
                  Opacity(
                    opacity: data.pendingDeleteId == tx.id ? 0.55 : 1,
                    child: IgnorePointer(
                      ignoring: data.pendingDeleteId == tx.id,
                      child: TransactionSearchRow(
                        key: ValueKey<int>(tx.id),
                        transaction: tx,
                        category: categoriesById[tx.categoryId],
                        account: accountsById[tx.accountId],
                        locale: widget.locale,
                        deleteMode: TransactionSearchRowDeleteMode.actionOnly,
                        convertedAmount: _convertedAmount(
                          tx: tx,
                          category: categoriesById[tx.categoryId],
                          slice: widget.slice,
                          currenciesByCode: currenciesByCode,
                          fxStatus: fxStatus,
                        ),
                        originalAmountLabel:
                            _shouldShowOriginalAmount(
                              tx: tx,
                              slice: widget.slice,
                              fxStatus: fxStatus,
                            )
                            ? l10n.analysisOriginalAmount
                            : null,
                        onTap: () => context.push('/home/edit/${tx.id}'),
                        onDelete: () => _controller.delete(tx.id),
                      ),
                    ),
                  ),
              if (data.rows.length > _visibleCount)
                TextButton(
                  onPressed: () =>
                      setState(() => _visibleCount += _kDrilldownPageSize),
                  child: Text(
                    l10n.analysisDrilldownShowMore(
                      data.rows.length - _visibleCount,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onEffect(SliceDrilldownEffect effect) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    switch (effect) {
      case SliceDrilldownDeleteFailedEffect():
        _messenger
          ?..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  bool _shouldShowOriginalAmount({
    required Transaction tx,
    required ChartSlice slice,
    required ChartsFxStatus? fxStatus,
  }) {
    if (fxStatus == null) return false;
    return tx.currency.code != slice.currencyCode &&
        slice.currencyCode == fxStatus.defaultCurrencyCode;
  }

  String? _convertedAmount({
    required Transaction tx,
    required Category? category,
    required ChartSlice slice,
    required Map<String, Currency> currenciesByCode,
    required ChartsFxStatus? fxStatus,
  }) {
    if (!_shouldShowOriginalAmount(tx: tx, slice: slice, fxStatus: fxStatus)) {
      return null;
    }
    final rate = fxStatus!.scaledRate(tx.currency.code);
    if (rate == null) return null;
    final fromCurrency = currenciesByCode[tx.currency.code] ?? tx.currency;
    final toCurrency =
        currenciesByCode[slice.currencyCode] ??
        Currency(code: slice.currencyCode, decimals: 2);
    final signedMinorUnits = category?.type == CategoryType.income
        ? tx.amountMinorUnits
        : -tx.amountMinorUnits;
    final convertedMinorUnits = CurrencyConverter.convertMinorUnits(
      amountMinorUnits: signedMinorUnits,
      rateScaledE9: rate,
      fromDecimals: fromCurrency.decimals,
      toDecimals: toCurrency.decimals,
    );
    return MoneyFormatter.formatSigned(
      amountMinorUnits: convertedMinorUnits,
      currency: toCurrency,
      locale: widget.locale,
    );
  }

  bool _showStaleRates({
    required ChartsFxStatus? fxStatus,
    required List<Transaction> rows,
    required ChartSlice slice,
  }) {
    if (fxStatus == null || rows.isEmpty) return false;
    final fetchedAts = <DateTime>[];
    for (final tx in rows) {
      if (tx.currency.code == slice.currencyCode) continue;
      final metadata = fxStatus.metadataForPair(
        tx.currency.code,
        slice.currencyCode,
      );
      if (metadata != null) {
        fetchedAts.add(metadata.fetchedAt);
      }
    }
    if (fetchedAts.isEmpty) return false;

    final oldest = fetchedAts.reduce((a, b) => b.isBefore(a) ? b : a);
    return DateTime.now().difference(oldest) > const Duration(hours: 1);
  }

  String _labelFor({
    required SelectedSlice selection,
    required ChartSlice slice,
    required Map<int, Category> categoriesById,
    required Map<int, Account> accountsById,
    required AppLocalizations l10n,
  }) {
    return switch (selection) {
      SelectedCategorySlice(:final categoryId) =>
        categoriesById[categoryId] == null
            ? slice.label
            : categoryDisplayName(categoriesById[categoryId]!, l10n),
      SelectedAccountSlice(:final accountId) =>
        accountsById[accountId]?.name ?? slice.label,
      SelectedCurrencySlice(:final currencyCode) => currencyCode,
    };
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.label,
    required this.count,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.currenciesByCode,
    required this.locale,
    required this.l10n,
    required this.showStaleRates,
  });

  final String label;
  final int count;
  final int totalMinorUnits;
  final String currencyCode;
  final Map<String, Currency> currenciesByCode;
  final String locale;
  final AppLocalizations l10n;
  final bool showStaleRates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency =
        currenciesByCode[currencyCode] ??
        Currency(code: currencyCode, decimals: 2);
    final total = MoneyFormatter.format(
      amountMinorUnits: totalMinorUnits,
      currency: currency,
      locale: locale,
    );
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    l10n.analysisTransactionCount(count),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (showStaleRates)
                    Text(
                      l10n.analysisRatesStale,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              total,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

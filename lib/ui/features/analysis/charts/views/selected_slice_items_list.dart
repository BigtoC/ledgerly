// Transactions card (slice drill-down) — sibling of `_ChartBody` inside
// `ChartsSection`'s Column; Main.dc.html lines 193-234. Renders nothing
// when no slice is selected, otherwise a card with a header (slice dot,
// label, "N transactions · total", optional stale-rate notice, close
// button) followed by `SliceTransactionRow`s with action-only delete.
// Owns its own snackbar undo wiring via `SliceDrilldownController`.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../../core/utils/color_palette.dart';
import '../../../../../core/utils/currency_converter.dart';
import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/category.dart';
import '../../../../../domain/models/currency.dart';
import '../../../../../domain/models/transaction.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/undo_snack_bar.dart';
import '../../../../core/theme/analysis_colors.dart';
import '../../../categories/views/category_display.dart';
import '../../search/view_models/analysis_providers.dart';
import '../view_models/charts_providers.dart';
import '../view_models/charts_selection_controller.dart';
import '../view_models/charts_state.dart';
import '../view_models/selected_slice.dart';
import '../view_models/slice_drilldown_controller.dart';
import 'slice_transaction_row.dart';

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
  late String _errorMessage;
  int _visibleCount = _kDrilldownPageSize;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(sliceDrilldownControllerProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.maybeOf(context);
    _errorMessage = AppLocalizations.of(context).errorSnackbarGeneric;
    _bindEffects(clearFirst: true);
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
    // Typing a search unmounts this list while the keepAlive controller still
    // commits the pending delete, which can fail (#150). Keep reporting, but
    // queue behind the current snackbar: it may be another screen's live Undo.
    _bindEffects(clearFirst: false);
    super.dispose();
  }

  /// The listener holds only the messenger and the message, never this
  /// State, so it can outlive the list.
  void _bindEffects({required bool clearFirst}) {
    final messenger = _messenger;
    final message = _errorMessage;
    _controller.setEffectListener((effect) {
      if (messenger == null || !messenger.mounted) return;
      switch (effect) {
        case SliceDrilldownDeleteFailedEffect():
          if (clearFirst) messenger.clearSnackBars();
          messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    });
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
      _messenger?.showUndoSnackBar(
        message: l10n.homeDeleteUndoSnackbar,
        undoLabel: l10n.commonUndo,
        onUndo: _controller.undoDelete,
      );
    });

    final colors = AnalysisColors.of(context);
    final divider = BoxDecoration(
      border: Border(top: BorderSide(color: colors.line)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          // The 1px border, then the card's own padding of 8 0.
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 9),
          child: AnimatedSize(
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
                      label: categoryDisplayNameForKey(
                        widget.slice.label,
                        l10n,
                      ),
                      color: colorForIndex(widget.slice.colorIndex),
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
                      onClose: ref
                          .read(chartsSelectionControllerProvider.notifier)
                          .clearSlice,
                    ),
                    // Account dimension only: filter the page by this
                    // account and show its categories (AC 7).
                    if (selection case SelectedAccountSlice(:final accountId))
                      _BridgeButton(
                        label: l10n.chartsSeeCategoriesIn(widget.slice.label),
                        onTap: () => ref
                            .read(chartsSelectionControllerProvider.notifier)
                            .setAccountFilter(accountId),
                      ),
                    if (data.rows.isEmpty)
                      Container(
                        decoration: divider,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.analysisDrilldownEmpty,
                          textAlign: TextAlign.center,
                          style: analysisText(
                            size: 14,
                            lineHeight: 20,
                            color: colors.fg2,
                          ),
                        ),
                      )
                    else
                      for (final tx in data.rows.take(_visibleCount))
                        Opacity(
                          opacity: data.pendingDeleteId == tx.id ? 0.55 : 1,
                          child: IgnorePointer(
                            ignoring: data.pendingDeleteId == tx.id,
                            child: SliceTransactionRow(
                              key: ValueKey<int>(tx.id),
                              transaction: tx,
                              category: categoriesById[tx.categoryId],
                              account: accountsById[tx.accountId],
                              locale: widget.locale,
                              convertedAmount: _convertedAmount(
                                tx: tx,
                                category: categoriesById[tx.categoryId],
                                slice: widget.slice,
                                currenciesByCode: currenciesByCode,
                                fxStatus: fxStatus,
                              ),
                              onTap: () => context.push('/home/edit/${tx.id}'),
                              onDelete: () => _controller.delete(tx.id),
                            ),
                          ),
                        ),
                    if (data.rows.length > _visibleCount)
                      Container(
                        decoration: divider,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Center(
                          child: TextButton(
                            onPressed: () => setState(
                              () => _visibleCount += _kDrilldownPageSize,
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.expText,
                              minimumSize: const Size(0, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              l10n.analysisDrilldownShowMore(
                                math.min(
                                  _kDrilldownPageSize,
                                  data.rows.length - _visibleCount,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0,
                                color: colors.expText,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _convertedAmount({
    required Transaction tx,
    required Category? category,
    required ChartSlice slice,
    required Map<String, Currency> currenciesByCode,
    required ChartsFxStatus? fxStatus,
  }) {
    if (fxStatus == null ||
        tx.currency.code == slice.currencyCode ||
        slice.currencyCode != fxStatus.defaultCurrencyCode) {
      return null;
    }
    final rate = fxStatus.scaledRate(tx.currency.code);
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
    if (fxStatus == null) return false;
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    // metadataForPair is null for a row already in the slice's currency.
    return rows.any(
      (tx) =>
          fxStatus
              .metadataForPair(tx.currency.code, slice.currencyCode)
              ?.fetchedAt
              .isBefore(cutoff) ??
          false,
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.label,
    required this.color,
    required this.count,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.currenciesByCode,
    required this.locale,
    required this.l10n,
    required this.showStaleRates,
    required this.onClose,
  });

  final String label;
  final Color color;
  final int count;
  final int totalMinorUnits;
  final String currencyCode;
  final Map<String, Currency> currenciesByCode;
  final String locale;
  final AppLocalizations l10n;
  final bool showStaleRates;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final currency =
        currenciesByCode[currencyCode] ??
        Currency(code: currencyCode, decimals: 2);
    final total = MoneyFormatter.format(
      amountMinorUnits: totalMinorUnits,
      currency: currency,
      locale: locale,
    );
    final subtitleStyle = analysisText(
      size: 13,
      lineHeight: 18,
      color: colors.fg2,
      tabular: true,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    label,
                    style: analysisText(
                      size: 16,
                      lineHeight: 24,
                      weight: FontWeight.w500,
                      color: colors.fg,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Wraps like one string would, but the total is one piece:
                // it never breaks mid-number and scales down only when it
                // alone is wider than the line (plan D2).
                Wrap(
                  children: [
                    Text(
                      '${l10n.analysisTransactionCount(count)} · ',
                      style: subtitleStyle,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        total,
                        maxLines: 1,
                        softWrap: false,
                        style: subtitleStyle,
                      ),
                    ),
                  ],
                ),
                if (showStaleRates) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.analysisRatesStale,
                    style: analysisText(
                      size: 13,
                      lineHeight: 18,
                      color: colors.fg2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onClose,
            tooltip: l10n.chartsCloseTransactions,
            icon: const Icon(Icons.close, size: 20),
            color: colors.fg2,
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              minimumSize: const Size(48, 48),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

/// `See categories in <Account>`: an outlined 44-high pill under the
/// header. Main.dc.html lines 205-211.
class _BridgeButton extends StatelessWidget {
  const _BridgeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AnalysisColors.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: colors.outline),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          button: true,
          child: Material(
            key: const ValueKey('sliceBridgeButton'),
            color: colors.card.withValues(alpha: 0),
            shape: shape,
            child: InkWell(
              customBorder: shape,
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  // 14 / 12 padding inside the 1 px border.
                  padding: const EdgeInsets.fromLTRB(15, 1, 13, 1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: analysisText(
                            size: 14,
                            lineHeight: 20,
                            weight: FontWeight.w500,
                            color: colors.fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right, size: 16, color: colors.fg),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

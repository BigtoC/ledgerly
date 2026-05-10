import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/category.dart';
import '../../../data/models/transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import 'analysis_providers.dart';
import 'category_search_detail_controller.dart';
import 'category_search_detail_state.dart';
import 'widgets/transaction_search_row.dart';

class CategorySearchDetailScreen extends ConsumerStatefulWidget {
  const CategorySearchDetailScreen({
    super.key,
    required this.categoryId,
    required this.query,
    required this.currencyCode,
  });

  final int categoryId;
  final String query;
  final String currencyCode;

  @override
  ConsumerState<CategorySearchDetailScreen> createState() =>
      _CategorySearchDetailScreenState();
}

class _CategorySearchDetailScreenState
    extends ConsumerState<CategorySearchDetailScreen> {
  CategorySearchPendingDelete? _lastShownPending;
  late final CategorySearchDetailController _controller;

  CategorySearchDetailControllerProvider get _provider =>
      categorySearchDetailControllerProvider(
        categoryId: widget.categoryId,
        query: widget.query,
        currencyCode: widget.currencyCode,
      );

  @override
  void initState() {
    super.initState();
    _controller = ref.read(_provider.notifier);
    _controller.setEffectListener(_onEffect);
  }

  @override
  void dispose() {
    _controller.setEffectListener(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    final state = ref.watch(_provider);

    final categoriesAsync = ref.watch(analysisCategoriesByIdProvider);
    final accountsAsync = ref.watch(analysisAccountsByIdProvider);
    final categoriesById =
        categoriesAsync.valueOrNull ?? const <int, Category>{};
    final accountsById = accountsAsync.valueOrNull ?? const {};

    final category = categoriesById[widget.categoryId];
    final appBarTitle = category == null
        ? ''
        : categoryDisplayName(category, l10n);
    final lookupsReady = categoriesAsync.hasValue && accountsAsync.hasValue;

    // Surface the undo snackbar on pendingDelete transitions (null → set).
    ref.listen(_provider, (_, next) {
      if (next is AsyncData<CategorySearchDetailState>) {
        final value = next.value;
        if (value is DetailData) {
          _maybeShowUndoSnackbar(context, value.pendingDelete);
        } else {
          _lastShownPending = null;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: SlidableAutoCloseBehavior(
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(l10n.analysisErrorMessage)),
          data: (s) => switch (s) {
            DetailLoading() => const Center(child: CircularProgressIndicator()),
            DetailEmpty() => Center(child: Text(l10n.analysisNoResults)),
            DetailData(:final days) when days.isEmpty => Center(
              child: Text(l10n.analysisNoResults),
            ),
            DetailData(
              :final days,
              :final overallSumMinorUnits,
              :final currency,
            ) =>
              !lookupsReady || category == null
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.analysisSearchTotal,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                MoneyFormatter.formatSigned(
                                  amountMinorUnits:
                                      category.type == CategoryType.income
                                      ? overallSumMinorUnits
                                      : -overallSumMinorUnits,
                                  currency: currency,
                                  locale: locale,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: category.type == CategoryType.income
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: days.length,
                            itemBuilder: (ctx, dayIdx) {
                              final day = days[dayIdx];
                              final daySigned =
                                  category.type == CategoryType.income
                                  ? day.daySumMinorUnits
                                  : -day.daySumMinorUnits;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      4,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat.yMMMd(
                                            locale,
                                          ).format(day.date),
                                          style: theme.textTheme.labelMedium,
                                        ),
                                        Text(
                                          MoneyFormatter.formatSigned(
                                            amountMinorUnits: daySigned,
                                            currency: currency,
                                            locale: locale,
                                          ),
                                          style: theme.textTheme.labelMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                  for (final tx in day.transactions)
                                    TransactionSearchRow(
                                      transaction: tx,
                                      category: categoriesById[tx.categoryId],
                                      account: accountsById[tx.accountId],
                                      locale: locale,
                                      onTap: () => _onEditRow(tx.id),
                                      onDelete: () => _onDeleteRow(tx.id),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
          },
        ),
      ),
    );
  }

  Future<void> _onEditRow(int id) async {
    // Reuse the global edit-transaction modal route; it's pushed onto the
    // root navigator so it overlays the analysis branch correctly.
    await context.push<Transaction>('/home/edit/$id');
    // No follow-up action — the underlying memo stream re-emits if the
    // transaction was edited (or not, if the memo no longer matches the
    // active query, in which case the row drops out naturally).
  }

  Future<void> _onDeleteRow(int id) async {
    await _controller.deleteTransaction(id);
  }

  void _maybeShowUndoSnackbar(
    BuildContext context,
    CategorySearchPendingDelete? pending,
  ) {
    final l10n = AppLocalizations.of(context);
    if (pending == null) {
      _lastShownPending = null;
      return;
    }
    if (_lastShownPending?.transaction.id == pending.transaction.id) return;
    _lastShownPending = pending;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.homeDeleteUndoSnackbar),
          duration: kUndoWindow,
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () {
              _controller.undoDelete();
            },
          ),
        ),
      );
  }

  void _onEffect(CategorySearchDetailEffect effect) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    switch (effect) {
      case CategorySearchDetailDeleteFailedEffect():
        messenger
          ?..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }
}

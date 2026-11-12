import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../../core/utils/money_formatter.dart';
import '../../../../../domain/models/category.dart';
import '../../../../../domain/models/transaction.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/undo_snack_bar.dart';
import '../../../categories/views/category_display.dart';
import '../view_models/analysis_providers.dart';
import '../view_models/category_search_detail_controller.dart';
import '../view_models/category_search_detail_state.dart';
import 'transaction_search_row.dart';

@Dependencies([
  CategorySearchDetailController,
  analysisCategoriesById,
  analysisAccountsById,
])
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
  Transaction? _lastShownPending;
  late final CategorySearchDetailController _controller;
  late ScaffoldMessengerState _messenger;
  late String _errorMessage;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
    _errorMessage = AppLocalizations.of(context).errorSnackbarGeneric;
    _bindEffects(clearFirst: true);
  }

  @override
  void dispose() {
    // A pending delete keeps the controller alive after a pop, and its commit
    // can still fail (#150). Keep reporting, but queue behind the current
    // snackbar instead of clearing it: it may be another screen's live Undo.
    _bindEffects(clearFirst: false);
    super.dispose();
  }

  /// The listener holds only the messenger and the message, never this
  /// State, so it can outlive the screen.
  void _bindEffects({required bool clearFirst}) {
    final messenger = _messenger;
    final message = _errorMessage;
    _controller.setEffectListener((effect) {
      if (!messenger.mounted) return;
      switch (effect) {
        case CategorySearchDetailDeleteFailedEffect():
          if (clearFirst) messenger.clearSnackBars();
          messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final theme = Theme.of(context);

    final state = ref.watch(_provider);

    final categoriesAsync = ref.watch(analysisCategoriesByIdProvider);
    final accountsAsync = ref.watch(analysisAccountsByIdProvider);
    final categoriesById = categoriesAsync.value ?? const <int, Category>{};
    final accountsById = accountsAsync.value ?? const {};

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
                                          DateFormat.yMMMd(locale)
                                              .format(day.date),
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
                                      onTap: () =>
                                          context.push('/home/edit/${tx.id}'),
                                      onDelete: () =>
                                          _controller.deleteTransaction(tx.id),
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

  void _maybeShowUndoSnackbar(BuildContext context, Transaction? pending) {
    final l10n = AppLocalizations.of(context);
    if (pending == null) {
      _lastShownPending = null;
      return;
    }
    if (_lastShownPending?.id == pending.id) return;
    _lastShownPending = pending;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showUndoSnackBar(
      message: l10n.homeDeleteUndoSnackbar,
      undoLabel: l10n.commonUndo,
      onUndo: () {
        _controller.undoDelete();
      },
    );
  }
}

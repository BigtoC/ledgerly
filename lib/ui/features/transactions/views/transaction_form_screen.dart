// `TransactionFormScreen` — Wave 2 §5 / §8 / §9 / §10 / Task 5.
//
// Required widget tree (PRD → Layout Primitives):
//
//   Scaffold(resizeToAvoidBottomInset: false)
//     └─ SafeArea
//         └─ Column
//             ├─ ConstrainedBox(max: height − keypad minimum)
//             │   └─ SingleChildScrollView (amount; category | account;
//             │      currency | date; memo; [shopping-list actions])
//             └─ Expanded → CalculatorKeypad, pinned to the bottom
//
// Issue #100: the form takes its natural height and the keypad's keys
// shrink (down to 48dp) into the height left over, so on a phone the form
// does not scroll. Only when even 48dp keys leave too little room (short
// phones, landscape, large text) does the form scroll.
//
// `resizeToAvoidBottomInset: false` is mandatory — the keypad must stay
// visible while the memo field's soft keyboard is open. Save lives in
// the AppBar (numeric-only keypad). Adaptive 600dp behavior is supplied
// by the router (`fullscreenDialog: true` + parentNavigatorKey).
//
// Task 5 additions:
//   - `mode` constructor parameter drives AppBar title and CTA set.
//   - AddTransactionMode: inline "Add to shopping list" action below
//     MemoField.
//   - EditShoppingListDraftMode: no AppBar save/delete; inline action row
//     with "Save to transaction" (primary) + "Save draft" (secondary) +
//     archived-ref warning text.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../../categories/view_models/categories_controller.dart';
import '../../categories/views/category_picker.dart';
import '../view_models/transaction_form_controller.dart';
import '../view_models/transaction_form_state.dart';
import 'account_picker_sheet.dart';
import 'account_selector_tile.dart';
import 'amount_display.dart';
import 'calculator_keypad.dart';
import 'category_chip.dart';
import 'currency_picker_sheet.dart';
import 'currency_selector_tile.dart';
import 'date_field.dart';
import 'memo_field.dart';
import 'memo_suggestions.dart';

@Dependencies([TransactionFormController, categoriesByType])
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.transactionId, this.mode});

  /// Edit-mode target id, parsed from `/home/edit/:id`.
  /// Retained for backward compat; prefer passing [mode] directly.
  final int? transactionId;

  /// Typed form mode. When null, the screen falls back to the legacy
  /// transactionId-based hydration (backward compat with Wave 2 routes).
  final TransactionFormMode? mode;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  /// Set after the first invalid save attempt so inline guidance kicks
  /// in (Wave 2 §9 inline validation).
  bool _showValidationHints = false;

  @override
  void initState() {
    super.initState();
    // Hydrate after the first frame so `ref.read` sees a built notifier
    // and `GoRouterState.of(context)` is reachable.
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    if (!mounted) return;
    final controller = ref.read(transactionFormControllerProvider.notifier);

    // Task 5: if a typed mode was passed directly, use it.
    final typedMode = widget.mode;
    if (typedMode != null) {
      switch (typedMode) {
        case AddTransactionMode(:final initialDate):
          unawaited(controller.hydrateForAdd(initialDate: initialDate));
        case DuplicateTransactionMode(:final sourceTransactionId):
          unawaited(controller.hydrateForDuplicate(sourceTransactionId));
        case EditTransactionMode(:final transactionId):
          unawaited(controller.hydrateForEdit(transactionId));
        case EditShoppingListDraftMode(:final shoppingListItemId):
          unawaited(controller.hydrateForShoppingListDraft(shoppingListItemId));
      }
      return;
    }

    // Legacy Wave 2 hydration via route extras / transactionId.
    final extra = GoRouterState.of(context).extra;
    // Wave 2 §10 contract: `{'duplicateSourceId': <int>}` from Home's
    // overflow→Duplicate path.
    int? duplicateSourceId;
    DateTime? initialDate;
    if (extra is Map) {
      if (extra['duplicateSourceId'] is int) {
        duplicateSourceId = extra['duplicateSourceId'] as int;
      }
      // Home's FAB / day-nav carries the currently selected day so the
      // form lands on that day instead of today (Wave 3 follow-up).
      // Ignored for Edit and Duplicate flows by design.
      if (extra['initialDate'] is DateTime) {
        initialDate = extra['initialDate'] as DateTime;
      }
    }
    final transactionId = widget.transactionId;
    if (transactionId != null) {
      unawaited(controller.hydrateForEdit(transactionId));
    } else if (duplicateSourceId != null) {
      unawaited(controller.hydrateForDuplicate(duplicateSourceId));
    } else {
      unawaited(controller.hydrateForAdd(initialDate: initialDate));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(transactionFormControllerProvider);
    final controller = ref.read(transactionFormControllerProvider.notifier);
    final activeMode = widget.mode ?? state.formMode;

    final appBarTitle = switch (activeMode) {
      EditShoppingListDraftMode() => l10n.shoppingListEditDraftTitle,
      EditTransactionMode() => l10n.txEditTitle,
      AddTransactionMode() || DuplicateTransactionMode() => l10n.txAddTitle,
    };

    // F1/F2: Auto-pop with ShoppingListEditResultMissingDraft when the draft
    // is not found during EditShoppingListDraftMode hydration. A
    // postFrameCallback is used to avoid calling context.pop() synchronously
    // during build (which would throw a navigation assertion).
    ref.listen(transactionFormControllerProvider, (prev, next) {
      if (next is TransactionFormEmpty &&
          next.reason == TransactionFormEmptyReason.draftNotFound &&
          widget.mode is EditShoppingListDraftMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop(const ShoppingListEditResultMissingDraft());
        });
      }
    });

    return PopScope(
      canPop: _canPop(state),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_blocksPopDuringMutation(state)) return;
        final shouldDiscard = await _confirmDiscard(context, l10n);
        if (shouldDiscard && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(appBarTitle),
          actions: switch (activeMode) {
            EditShoppingListDraftMode() => const <Widget>[],
            EditTransactionMode() => <Widget>[
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.commonDelete,
                onPressed:
                    state is TransactionFormData &&
                        !state.isDeleting &&
                        !state.isSaving
                    ? () => _delete(context, l10n, controller)
                    : null,
              ),
              TextButton(
                onPressed: state.canSave
                    ? () => _save(context, l10n, controller)
                    : null,
                child: Text(l10n.commonSave),
              ),
            ],
            AddTransactionMode() || DuplicateTransactionMode() => <Widget>[
              TextButton(
                onPressed: state.canSave
                    ? () => _save(context, l10n, controller)
                    : null,
                child: Text(l10n.commonSave),
              ),
            ],
          },
        ),
        body: SafeArea(
          child: switch (state) {
            TransactionFormLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TransactionFormEmpty(:final reason) => _EmptyState(
              reason: reason,
              onCreateAccount: () => _onCreateAccount(context, controller),
              onBackToHome: () => context.pop(),
            ),
            TransactionFormError(:final error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('$error'),
              ),
            ),
            TransactionFormData() => _buildForm(
              context,
              l10n,
              state,
              controller,
              activeMode: activeMode,
            ),
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormData state,
    TransactionFormController controller, {
    required TransactionFormMode activeMode,
  }) {
    final showAmountError = _showValidationHints && state.amountMinorUnits == 0;
    final showCategoryError =
        _showValidationHints && state.selectedCategory == null;
    final showAccountError =
        _showValidationHints && state.selectedAccount == null;
    final controlsLocked = _blocksPopDuringMutation(state);

    final isShoppingListDraftMode = activeMode is EditShoppingListDraftMode;

    return IgnorePointer(
      ignoring: controlsLocked,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            ConstrainedBox(
              // The form takes its natural height and the keypad's keys
              // shrink into what is left, down to 48dp. Past that, the form
              // scrolls rather than push the keypad off screen.
              constraints: BoxConstraints(
                maxHeight: math.max(
                  0,
                  constraints.maxHeight - CalculatorKeypad.minHeight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AmountDisplay(
                      keypad: state.keypad,
                      currency: state.displayCurrency,
                      currencyTouched: state.currencyTouched,
                      hasError: showAmountError,
                      onEquals: controller.equals,
                    ),
                    if (showAmountError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 8),
                        child: Text(
                          l10n.txAmountRequired,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CategoryChip(
                            category: state.selectedCategory,
                            hasError: showCategoryError,
                            onTap: () =>
                                _onTapCategoryChip(context, l10n, controller),
                          ),
                        ),
                        Expanded(
                          child: AccountSelectorTile(
                            account: state.selectedAccount,
                            hasError: showAccountError,
                            onTap: () => _onTapAccountTile(
                              context,
                              l10n,
                              state,
                              controller,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CurrencySelectorTile(
                            currency: state.displayCurrency,
                            onTap: () => _onTapCurrencyTile(
                              context,
                              l10n,
                              state,
                              controller,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DateField(
                            value: state.date,
                            onChanged: controller.setDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MemoField(
                      initialValue: state.memo,
                      onChanged: controller.setMemo,
                    ),
                    if (state.selectedCategory case final category?)
                      MemoSuggestions(
                        categoryId: category.id,
                        onSelected: controller.setMemo,
                      ),
                    // Shopping-list inline action rows — shown below MemoField.
                    if (isShoppingListDraftMode)
                      _ShoppingListDraftActions(
                        state: state,
                        l10n: l10n,
                        onSaveToTransaction: () => _submitDraft(
                          context,
                          controller.convertDraft,
                          l10n.shoppingListConvertFailedSnackbar,
                        ),
                        onSaveDraft: () => _submitDraft(
                          context,
                          controller.saveDraft,
                          l10n.shoppingListSaveFailedSnackbar,
                        ),
                      )
                    else if (activeMode is AddTransactionMode)
                      _AddToShoppingListAction(
                        canSaveDraft: state.canSaveDraft,
                        label: l10n.shoppingListAddToListAction,
                        inFlight:
                            state.submissionAction ==
                            TransactionFormSubmissionAction.saveDraft,
                        onPressed: () =>
                            _saveAsDraft(context, l10n, controller),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: CalculatorKeypad(
                  decimals: state.displayCurrency?.decimals ?? 2,
                  onDigit: controller.appendDigit,
                  onDecimal: controller.appendDecimal,
                  onBackspace: controller.backspace,
                  onClear: controller.clearAmount,
                  onOperator: controller.applyOperator,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Shopping-list command wrappers ----------

  /// Called from AddTransactionMode — saves as draft and pops with null.
  Future<void> _saveAsDraft(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormController controller,
  ) async {
    final outcome = await controller.saveDraft();
    if (!context.mounted) return;
    switch (outcome) {
      case DraftSubmissionOk():
        // Add mode: close the form (pop with null — no Transaction result).
        context.pop(null);
      case DraftSubmissionIgnored():
        // The guard prevented saving (canSaveDraft was false or a
        // submission was already in flight) — do NOT pop.
        break;
      case DraftSubmissionFailed():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shoppingListSaveFailedSnackbar)),
        );
    }
  }

  /// Called from EditShoppingListDraftMode — runs [submit] (saveDraft or
  /// convertDraft) and pops with its result.
  Future<void> _submitDraft(
    BuildContext context,
    Future<DraftSubmissionOutcome> Function() submit,
    String failureMessage,
  ) async {
    final outcome = await submit();
    if (!context.mounted) return;
    switch (outcome) {
      case DraftSubmissionOk(:final result):
        context.pop(result);
      case DraftSubmissionIgnored():
        break;
      case DraftSubmissionFailed():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  bool _isDirty(TransactionFormState state) {
    return state is TransactionFormData && state.isDirty;
  }

  bool _blocksPopDuringMutation(TransactionFormState state) {
    return state is TransactionFormData &&
        (state.isSaving ||
            state.isDeleting ||
            state.submissionAction != TransactionFormSubmissionAction.none);
  }

  bool _canPop(TransactionFormState state) {
    if (_blocksPopDuringMutation(state)) return false;
    return !_isDirty(state);
  }

  Future<bool> _confirmDiscard(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.txDiscardConfirmTitle),
        content: Text(l10n.txDiscardConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.txDiscardAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _save(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormController controller,
  ) async {
    final outcome = await controller.save();
    // `mounted` guards the setState below; `context.mounted` the context.
    if (!mounted || !context.mounted) return;
    switch (outcome) {
      case SaveTransactionSaved(:final transaction):
        context.pop(transaction);
      case SaveTransactionInvalid():
        // canSave was false — surface inline hints.
        setState(() => _showValidationHints = true);
      case SaveTransactionFailed():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.txSaveFailedSnackbar)));
    }
  }

  Future<void> _delete(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.txDeleteConfirmTitle),
        content: Text(l10n.txDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final outcome = await controller.deleteExisting();
    if (!context.mounted) return;
    switch (outcome) {
      case DeleteTransactionDeleted():
        context.pop();
      case DeleteTransactionNotFound():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.txTransactionNotFound)));
        context.pop();
      case DeleteTransactionIgnored():
        break;
      case DeleteTransactionFailed():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.txDeleteFailedSnackbar)));
    }
  }

  Future<void> _onTapCategoryChip(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormController controller,
  ) async {
    // Wave 2 §7.1 — the controller decides BEFORE the picker opens whether
    // it is even useful; with no categories at all, route straight to
    // /settings/categories so the user can create one.
    final outcome = await controller.resolveCategoryChipTap();
    if (!context.mounted) return;
    switch (outcome) {
      case CategoryChipTapOpenPicker():
        final picked = await showCategoryPicker(context);
        if (picked == null || !context.mounted) return; // dismissed
        controller.selectCategory(picked);
      case CategoryChipTapManageCategories():
        await context.push('/settings/categories');
      case CategoryChipTapFailed():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  Future<void> _onTapAccountTile(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormData state,
    TransactionFormController controller,
  ) async {
    final picked = await showAccountPickerSheet(context);
    if (picked == null || !context.mounted) return;

    // When the user has manually selected a currency, account changes
    // leave displayCurrency and amount unchanged — skip the
    // destructive clear-currency confirmation.
    if (state.currencyTouched) {
      controller.selectAccount(picked);
      return;
    }

    final currentCode = state.displayCurrency?.code;
    final newCode = picked.currency.code;
    final currencyChanges = currentCode != null && currentCode != newCode;
    final hasDestructiveInput =
        state.amountMinorUnits > 0 || state.keypad.hasVisibleInput;

    if (currencyChanges && hasDestructiveInput) {
      final confirmed = await _confirmCurrencyChange(
        context,
        l10n,
        l10n.txCurrencyChangeConfirmBody,
      );
      if (!context.mounted) return;
      if (!confirmed) return;
      controller.selectAccount(picked, clearAmountOnCurrencyChange: true);
      return;
    }
    controller.selectAccount(picked);
  }

  Future<void> _onTapCurrencyTile(
    BuildContext context,
    AppLocalizations l10n,
    TransactionFormData state,
    TransactionFormController controller,
  ) async {
    final picked = await showTxCurrencyPickerSheet(context);
    if (picked == null || !context.mounted) return;
    final currentCode = state.displayCurrency?.code;
    final currencyChanges = currentCode != null && currentCode != picked.code;
    final hasDestructiveInput =
        state.amountMinorUnits > 0 || state.keypad.hasVisibleInput;

    if (currencyChanges && hasDestructiveInput) {
      final confirmed = await _confirmCurrencyChange(
        context,
        l10n,
        l10n.txCurrencyPickerChangeConfirmBody,
      );
      if (!context.mounted) return;
      if (!confirmed) return;
      controller.selectCurrency(picked, clearAmountOnChange: true);
      return;
    }
    controller.selectCurrency(picked);
  }

  Future<bool> _confirmCurrencyChange(
    BuildContext context,
    AppLocalizations l10n,
    String body,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.txCurrencyChangeConfirmTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.txCurrencyChangeConfirmAction),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _onCreateAccount(
    BuildContext context,
    TransactionFormController controller,
  ) {
    // After /settings/manage-accounts/new pops, re-run the current hydration mode so add
    // and duplicate flows both recover correctly.
    context.push('/settings/manage-accounts/new').then((_) {
      if (!mounted) return;
      unawaited(controller.retryHydration());
    });
  }
}

// ---------------------------------------------------------------------------
// Shopping-list inline action widgets — Task 5
// ---------------------------------------------------------------------------

/// "Add to shopping list" inline button shown in AddTransactionMode, below
/// the MemoField. Disabled until [canSaveDraft] is true.
class _AddToShoppingListAction extends StatelessWidget {
  const _AddToShoppingListAction({
    required this.canSaveDraft,
    required this.label,
    required this.inFlight,
    required this.onPressed,
  });

  final bool canSaveDraft;
  final String label;
  final bool inFlight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton(
        key: const Key('addToShoppingListButton'),
        onPressed: canSaveDraft && !inFlight ? onPressed : null,
        child: inFlight
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}

/// Inline action row shown in EditShoppingListDraftMode, below the MemoField.
/// Shows archived-ref warnings when applicable.
class _ShoppingListDraftActions extends StatelessWidget {
  const _ShoppingListDraftActions({
    required this.state,
    required this.l10n,
    required this.onSaveToTransaction,
    required this.onSaveDraft,
  });

  final TransactionFormData state;
  final AppLocalizations l10n;
  final VoidCallback onSaveToTransaction;
  final VoidCallback onSaveDraft;

  @override
  Widget build(BuildContext context) {
    final inFlight =
        state.submissionAction != TransactionFormSubmissionAction.none;
    final convertInFlight =
        state.submissionAction == TransactionFormSubmissionAction.convertDraft;
    final saveInFlight =
        state.submissionAction == TransactionFormSubmissionAction.saveDraft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Archived-ref warnings.
        if (state.selectedAccountIsArchived)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.shoppingListArchivedAccountWarning,
              key: const Key('archivedAccountWarning'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        if (state.selectedCategoryIsArchived)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l10n.shoppingListArchivedCategoryWarning,
              key: const Key('archivedCategoryWarning'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
        // "Save to transaction" — primary CTA.
        FilledButton(
          key: const Key('saveToTransactionButton'),
          onPressed: state.canConvertDraft && !inFlight
              ? onSaveToTransaction
              : null,
          child: convertInFlight
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.shoppingListSaveToTransactionAction),
        ),
        const SizedBox(height: 8),
        // "Save draft" — secondary CTA.
        OutlinedButton(
          key: const Key('saveDraftButton'),
          onPressed: state.canSaveDraft && !inFlight ? onSaveDraft : null,
          child: saveInFlight
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.shoppingListSaveDraftAction),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.reason,
    required this.onCreateAccount,
    required this.onBackToHome,
  });

  final TransactionFormEmptyReason reason;
  final VoidCallback onCreateAccount;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // draftNotFound: auto-pop is already in flight via the ref.listen in the
    // parent screen — render nothing as a safe fallback.
    if (reason == TransactionFormEmptyReason.draftNotFound) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              reason == TransactionFormEmptyReason.noActiveAccount
                  ? Icons.account_balance_wallet_outlined
                  : Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              reason == TransactionFormEmptyReason.noActiveAccount
                  ? l10n.txAccountEmpty
                  : l10n.txTransactionNotFound,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (reason == TransactionFormEmptyReason.noActiveAccount)
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.txCreateAccountCta),
                onPressed: onCreateAccount,
              )
            else
              FilledButton(
                onPressed: onBackToHome,
                child: Text(l10n.commonCancel),
              ),
          ],
        ),
      ),
    );
  }
}

// Recurring rule create/edit form.
//
// Pure projection of [recurringRuleFormControllerProvider]. Save runs
// `repo.insert/update` and then immediately fires
// `RecurringGenerationUseCase.executeForRule` so the user sees today's
// pending row on Home (Wave 3) without waiting for the next cold start.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../l10n/app_localizations.dart';
import '../categories/categories_controller.dart';
import '../categories/widgets/category_picker.dart';
import '../transactions/widgets/account_picker_sheet.dart';
import '../transactions/widgets/account_selector_tile.dart';
import '../transactions/widgets/amount_display.dart';
import '../transactions/widgets/calculator_keypad.dart';
import '../transactions/widgets/category_chip.dart';
import 'recurring_rule_form_controller.dart';
import 'recurring_rule_form_state.dart';
import 'recurring_rules_providers.dart';

class RecurringRuleFormScreen extends ConsumerStatefulWidget {
  const RecurringRuleFormScreen({super.key, this.ruleId});

  final int? ruleId;

  @override
  ConsumerState<RecurringRuleFormScreen> createState() =>
      _RecurringRuleFormScreenState();
}

class _RecurringRuleFormScreenState
    extends ConsumerState<RecurringRuleFormScreen> {
  late final TextEditingController _memoCtl;
  late final TextEditingController _dayOfMonthCtl;
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _memoCtl = TextEditingController();
    _dayOfMonthCtl = TextEditingController();
  }

  @override
  void dispose() {
    _memoCtl.dispose();
    _dayOfMonthCtl.dispose();
    super.dispose();
  }

  void _hydrate(RecurringRuleFormState s) {
    if (_hydrated) return;
    _memoCtl.text = s.memo;
    if (s.dayOfMonth != null) {
      _dayOfMonthCtl.text = s.dayOfMonth!.toString();
    }
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = recurringRuleFormControllerProvider(ruleId: widget.ruleId);
    final asyncState = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return asyncState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.recurringFormCreateTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.recurringFormCreateTitle)),
        body: Center(child: Text('$e')),
      ),
      data: (state) {
        _hydrate(state);
        return _FormBody(
          state: state,
          controller: controller,
          providerKey: provider,
          memoCtl: _memoCtl,
          dayOfMonthCtl: _dayOfMonthCtl,
        );
      },
    );
  }
}

class _FormBody extends ConsumerWidget {
  const _FormBody({
    required this.state,
    required this.controller,
    required this.providerKey,
    required this.memoCtl,
    required this.dayOfMonthCtl,
  });

  final RecurringRuleFormState state;
  final RecurringRuleFormController controller;
  final RecurringRuleFormControllerProvider providerKey;
  final TextEditingController memoCtl;
  final TextEditingController dayOfMonthCtl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final title = state.isEdit
        ? l10n.recurringFormEditTitle
        : l10n.recurringFormCreateTitle;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: state.isLoading ? null : () => _onSave(context, ref),
            child: Text(
              state.isEdit
                  ? l10n.recurringSaveUpdate
                  : l10n.recurringSaveCreate,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.formError != null)
                    _FormErrorBanner(error: state.formError!),
                  if (state.isEdit && (state.pendingItemCount ?? 0) > 0) ...[
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.recurringEditWillNotAffectPending(
                            state.pendingItemCount!,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // The "Name" field is the rule's memo — recurring rules don't
                  // have a separate display name (PRD: memo doubles as label).
                  Focus(
                    onFocusChange: (has) {
                      if (!has) controller.touchMemo();
                    },
                    child: TextField(
                      controller: memoCtl,
                      decoration: InputDecoration(
                        labelText: l10n.recurringFormNamePlaceholder,
                        errorText: state.nameError != null
                            ? l10n.recurringFieldRequired
                            : null,
                      ),
                      onChanged: controller.updateMemo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Calculator-driven amount display. The keypad lives at the
                  // bottom of the screen (outside this ListView) so it can't
                  // be dismissed mid-entry by the soft keyboard.
                  AmountDisplay(keypad: state.keypad, currency: state.currency),
                  const SizedBox(height: 16),
                  _CategoryPickerTile(
                    state: state,
                    onPick: (cat) => controller.updateCategory(cat.id),
                  ),
                  const SizedBox(height: 8),
                  _AccountPickerTile(
                    state: state,
                    onPick: (acc) => controller.updateAccount(acc.id),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: state.frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text(l10n.recurringFrequencyDaily),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text(l10n.recurringFrequencyWeekly),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text(l10n.recurringFrequencyMonthly),
                      ),
                      DropdownMenuItem(
                        value: 'yearly',
                        child: Text(l10n.recurringFrequencyYearly),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      controller.updateFrequency(v);
                      // The controller's `updateFrequency` may default
                      // dayOfMonth to today.day (clamped to 28) when switching
                      // into monthly/yearly. Sync the visible TextEditingController.
                      if (v == 'monthly' || v == 'yearly') {
                        final today = DateTime.now();
                        final defaulted = today.day > 28 ? 28 : today.day;
                        final next = state.dayOfMonth ?? defaulted;
                        dayOfMonthCtl.text = next.toString();
                      } else {
                        dayOfMonthCtl.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _FrequencyFields(
                    state: state,
                    controller: controller,
                    dayOfMonthCtl: dayOfMonthCtl,
                  ),
                  const SizedBox(height: 24),
                  if (state.isEdit)
                    OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline),
                      label: Text(l10n.recurringDeleteRule),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            CalculatorKeypad(
              decimals: state.currency.decimals,
              onDigit: controller.appendDigit,
              onDecimal: controller.appendDecimal,
              onBackspace: controller.backspace,
              onClear: controller.clearAmount,
              onOperator: controller.applyOperator,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);
    final wasEdit = state.isEdit;
    final id = await controller.save();
    if (id == null) return;
    if (!context.mounted) return;
    final updated = ref.read(providerKey).valueOrNull;
    if (updated?.postSaveGenerationFailed ?? false) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.recurringSavedButGenerationFailed)),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasEdit ? l10n.recurringSavedUpdate : l10n.recurringSavedCreate,
          ),
        ),
      );
    }
    navigator.pop();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.recurringDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recurringDeleteRule),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    await controller.deleteRule();
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(l10n.recurringDeletedSnack)));
    navigator.pop();
  }
}

class _FormErrorBanner extends StatelessWidget {
  const _FormErrorBanner({required this.error});
  final RecurringFormError error;
  @override
  Widget build(BuildContext context) {
    final detail = switch (error) {
      ArchivedRefErr(:final detail) => detail,
      UnknownErr(:final detail) => detail,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            detail,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}

class _FrequencyFields extends StatelessWidget {
  const _FrequencyFields({
    required this.state,
    required this.controller,
    required this.dayOfMonthCtl,
  });

  final RecurringRuleFormState state;
  final RecurringRuleFormController controller;
  final TextEditingController dayOfMonthCtl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (state.frequency) {
      case 'daily':
        return Text(l10n.recurringDailyHelper);
      case 'weekly':
        const labels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (i) {
            final selected = state.dayOfWeek == i;
            return FilterChip(
              label: SizedBox(width: 32, child: Center(child: Text(labels[i]))),
              selected: selected,
              onSelected: (_) => controller.updateDayOfWeek(i),
            );
          }),
        );
      case 'monthly':
        return _DayOfMonthRow(
          state: state,
          controller: controller,
          dayOfMonthCtl: dayOfMonthCtl,
        );
      case 'yearly':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: state.monthOfYear,
              decoration: const InputDecoration(labelText: 'Month'),
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text((i + 1).toString()),
                ),
              ),
              onChanged: controller.updateMonthOfYear,
            ),
            const SizedBox(height: 12),
            _DayOfMonthRow(
              state: state,
              controller: controller,
              dayOfMonthCtl: dayOfMonthCtl,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _DayOfMonthRow extends StatelessWidget {
  const _DayOfMonthRow({
    required this.state,
    required this.controller,
    required this.dayOfMonthCtl,
  });

  final RecurringRuleFormState state;
  final RecurringRuleFormController controller;
  final TextEditingController dayOfMonthCtl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = state.dayOfMonth ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: value > 1
                  ? () {
                      final next = value - 1;
                      dayOfMonthCtl.text = '$next';
                      controller.updateDayOfMonth(next);
                    }
                  : null,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 64,
              child: TextField(
                controller: dayOfMonthCtl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed == null || parsed < 1 || parsed > 31) return;
                  controller.updateDayOfMonth(parsed);
                },
              ),
            ),
            IconButton(
              onPressed: value < 31
                  ? () {
                      final next = value + 1;
                      dayOfMonthCtl.text = '$next';
                      controller.updateDayOfMonth(next);
                    }
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Text(
          l10n.recurringDayOfMonthHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Tile that opens the category picker and renders the selected category
/// (icon + localized name) once chosen. Reuses [CategoryChip] from the
/// transactions slice — both forms pick from the same expense-category
/// universe and want the same affordance.
class _CategoryPickerTile extends ConsumerWidget {
  const _CategoryPickerTile({required this.state, required this.onPick});

  final RecurringRuleFormState state;
  final void Function(Category) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(
      categoriesByTypeProvider(CategoryType.expense),
    );
    final selected = asyncCategories.maybeWhen(
      data: (list) {
        final id = state.categoryId;
        if (id == null) return null;
        for (final c in list) {
          if (c.id == id) return c;
        }
        return null;
      },
      orElse: () => null,
    );
    return CategoryChip(
      key: const ValueKey('recurringForm:categoryPicker'),
      category: selected,
      hasError: state.categoryError != null,
      onTap: () async {
        final picked = await showCategoryPicker(
          context,
          type: CategoryType.expense,
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

/// Tile that opens the shared account picker and renders the selected
/// account once chosen. Reuses [AccountSelectorTile] from the
/// transactions slice for visual parity.
class _AccountPickerTile extends ConsumerWidget {
  const _AccountPickerTile({required this.state, required this.onPick});

  final RecurringRuleFormState state;
  final void Function(Account) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAccounts = ref.watch(recurringActiveAccountsProvider);
    final selected = asyncAccounts.maybeWhen(
      data: (list) {
        final id = state.accountId;
        if (id == null) return null;
        for (final account in list) {
          if (account.id == id) return account;
        }
        return null;
      },
      orElse: () => null,
    );
    return AccountSelectorTile(
      key: const ValueKey('recurringForm:accountPicker'),
      account: selected,
      hasError: state.accountError != null,
      onTap: () async {
        final picked = await showAccountPickerSheet(context);
        if (picked != null) onPick(picked);
      },
    );
  }
}

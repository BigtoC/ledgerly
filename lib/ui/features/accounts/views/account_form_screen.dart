// Account form screen — add/edit a single account (plan §3.1, §5).
//
// Route contract:
//   - `/settings/manage-accounts/new`  → `AccountFormScreen()` (Add mode).
//   - `/settings/manage-accounts/:id`  → `AccountFormScreen(accountId: id)`
//     (Edit mode).
//
// Invalid `:id` path params are a router-level concern (Wave 0 §2.4)
// and do not land here. If the edit-mode hydration cannot load the
// requested row (e.g. deleted while the user was on another screen),
// the screen renders a recoverable not-found message and pops back to
// `/settings`.
//
// Save calls `accountRepository.save(Account(...))` with `id == 0` for
// Add mode. On success the form calls `context.pop(savedAccountId)`
// with the int returned by the repository — callers can ignore the
// result and rely on the Accounts list stream for refresh.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/color_palette.dart';
import '../../../../core/utils/icon_registry.dart';
import '../../../../domain/models/account.dart';
import '../../../../domain/models/account_type.dart';
import '../../../../domain/models/currency.dart';
import '../../../../l10n/app_localizations.dart';
import '../view_models/accounts_providers.dart';
import '../view_models/accounts_state.dart';
import 'account_type_display.dart';
import 'account_type_picker_sheet.dart';
import 'amount_minor_units_field.dart';
import 'currency_picker_sheet.dart';

class const AccountFormScreen({super.key, final int? accountId})
    extends ConsumerStatefulWidget {
  bool get isEdit => accountId != null;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  late final TextEditingController _nameCtrl;
  AccountType? _type;
  Currency? _currency;
  int _openingBalanceMinorUnits = 0;
  bool _openingBalanceValid = true;
  String? _icon;
  int _color = 10;
  bool _saving = false;
  String? _errorMessage;

  bool _hydrating = true;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromProvider());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _hydrateFromProvider() async {
    final seed = await ref.read(
      accountFormSeedDataProvider(widget.accountId).future,
    );
    if (!mounted) return;
    if (seed.isMissing) {
      setState(() {
        _hydrating = false;
        _notFound = true;
      });
      return;
    }

    setState(() {
      final account = seed.account;
      if (account != null) {
        _nameCtrl.text = account.name;
        _type = seed.accountType;
        _currency = account.currency;
        _openingBalanceMinorUnits = account.openingBalanceMinorUnits;
        _icon = account.icon;
        _color = account.color ?? 10;
      } else {
        _currency = _currency ?? seed.defaultCurrency;
      }
      _hydrating = false;
    });
  }

  bool get _canSave =>
      !_saving &&
      _nameCtrl.text.trim().isNotEmpty &&
      _type != null &&
      _currency != null &&
      _openingBalanceValid;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _type == null || _currency == null) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final draft = Account(
      id: widget.accountId ?? 0,
      name: name,
      accountTypeId: _type!.id,
      currency: _currency!,
      openingBalanceMinorUnits: _openingBalanceMinorUnits,
      icon: _icon,
      color: _color,
      sortOrder: null,
    );
    final outcome = await ref.read(accountFormActionsProvider).save(draft);
    if (!mounted) return;
    switch (outcome) {
      case SaveAccountOk(:final accountId):
        context.pop(accountId);
      case SaveAccountCurrencyLocked():
        setState(() {
          _saving = false;
          _errorMessage = AppLocalizations.of(context)
              .accountFormCurrencyLockedError;
        });
      case SaveAccountFailed():
        setState(() {
          _saving = false;
          _errorMessage = AppLocalizations.of(context).errorSnackbarGeneric;
        });
    }
  }

  void _popOrGoSettings(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_notFound) {
      return _NotFoundSurface(
        message: l10n.accountsFormNotFound,
        onDismiss: () => _popOrGoSettings(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit
              ? l10n.accountsFormEditTitle
              : l10n.accountsFormAddTitle,
        ),
      ),
      body: _hydrating
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('accountForm:name'),
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.accountsFormName,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _FieldHeader(label: l10n.accountsFormType),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('accountForm:type'),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text(
                        _type == null
                            ? l10n.accountsFormPickType
                            : accountTypeDisplayName(_type!, l10n),
                      ),
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await showAccountTypePickerSheet(
                                context,
                              );
                              if (!mounted) return;
                              if (picked != null) {
                                setState(() {
                                  _type = picked;
                                  _currency ??= picked.defaultCurrency;
                                  _icon ??= picked.icon;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    _FieldHeader(label: l10n.accountsFormCurrency),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      key: const ValueKey('accountForm:currency'),
                      onPressed: _saving
                          ? null
                          : () async {
                              final picked = await showCurrencyPickerSheet(
                                context,
                              );
                              if (!mounted) return;
                              if (picked != null) {
                                setState(() => _currency = picked);
                              }
                            },
                      child: Text(
                        _currency?.code ?? l10n.accountsFormPickCurrency,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_currency != null)
                      AmountMinorUnitsField(
                        key: ValueKey(
                          'accountForm:openingBalance:${_currency!.code}',
                        ),
                        currency: _currency!,
                        locale: Localizations.localeOf(context).toString(),
                        initialMinorUnits: _openingBalanceMinorUnits,
                        labelText: l10n.accountsFormOpeningBalance,
                        onChanged: (value) {
                          setState(() {
                            if (value == null) {
                              _openingBalanceValid = false;
                            } else {
                              _openingBalanceValid = true;
                              _openingBalanceMinorUnits = value;
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    _FieldHeader(label: l10n.accountsFormColor),
                    const SizedBox(height: 4),
                    _ColorSwatches(
                      selected: _color,
                      onSelected: (idx) => setState(() => _color = idx),
                    ),
                    const SizedBox(height: 16),
                    _FieldHeader(label: l10n.accountsFormIcon),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final iconKey in const [
                          'wallet',
                          'trending_up',
                          'savings',
                          'payments',
                        ])
                          _IconSelector(
                            iconKey: iconKey,
                            selected: _icon == iconKey,
                            onTap: () => setState(() => _icon = iconKey),
                          ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _popOrGoSettings(context),
                            child: Text(l10n.commonCancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('accountForm:save'),
                            onPressed: _canSave ? _save : null,
                            child: Text(l10n.commonSave),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class const _FieldHeader({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleSmall);
}

class const _ColorSwatches({
  required final int selected,
  required final ValueChanged<int> onSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < kCategoryColorPalette.length; i++)
          GestureDetector(
            key: ValueKey('accountForm:color:$i'),
            onTap: () => onSelected(i),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorForIndex(i),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == i
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class const _IconSelector({
  required final String iconKey,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      key: ValueKey('accountForm:icon:$iconKey'),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(iconForKey(iconKey), color: color, size: 20),
      ),
    );
  }
}

class const _NotFoundSurface({
  required final String message,
  required final VoidCallback onDismiss,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Auto-pop on first build so users don't sit staring at an error
    // screen; leaves a short dismissable UI in case pop is not yet
    // ready (e.g. initial app launch via deep link).
    WidgetsBinding.instance.addPostFrameCallback((_) => onDismiss());
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onDismiss,
                  child: Text(AppLocalizations.of(context).commonCancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

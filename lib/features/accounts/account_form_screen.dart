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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/color_palette.dart';
import '../../core/utils/icon_registry.dart';
import '../../data/models/account.dart';
import '../../data/models/account_type.dart';
import '../../data/models/currency.dart';
import '../../l10n/app_localizations.dart';
import 'accounts_providers.dart';
import 'widgets/account_type_display.dart';
import 'widgets/account_type_picker_sheet.dart';
import 'widgets/amount_minor_units_field.dart';
import 'widgets/currency_picker_sheet.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.accountId});

  final int? accountId;

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

  bool _hydrating = false;
  bool _notFound = false;
  bool _defaultCurrencyResolved = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _hydrating = true;
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
        _defaultCurrencyResolved = true;
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
      _defaultCurrencyResolved = true;
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
    try {
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
      final id = await ref.read(accountFormActionsProvider).save(draft);
      if (mounted) context.pop(id);
    } catch (_) {
      setState(() {
        _saving = false;
        _errorMessage = AppLocalizations.of(context).errorSnackbarGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_notFound) {
      return _NotFoundSurface(
        message: l10n.accountsFormNotFound,
        onDismiss: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/settings');
          }
        },
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
      body: _hydrating || (!widget.isEdit && !_defaultCurrencyResolved)
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
                      children:
                          const [
                                _IconChip(iconKey: 'wallet'),
                                _IconChip(iconKey: 'trending_up'),
                                _IconChip(iconKey: 'savings'),
                                _IconChip(iconKey: 'payments'),
                              ]
                              .map(
                                (chip) => _IconSelector(
                                  iconKey: chip.iconKey,
                                  selected: _icon == chip.iconKey,
                                  onTap: () =>
                                      setState(() => _icon = chip.iconKey),
                                ),
                              )
                              .toList(),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
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
                                : () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/settings');
                                    }
                                  },
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

class _FieldHeader extends StatelessWidget {
  const _FieldHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleSmall);
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

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

class _IconChip {
  const _IconChip({required this.iconKey});
  final String iconKey;
}

class _IconSelector extends StatelessWidget {
  const _IconSelector({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

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

class _NotFoundSurface extends StatelessWidget {
  const _NotFoundSurface({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

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

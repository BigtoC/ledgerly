// Account-type picker sheet (plan §5, §12 risk #5).
//
// Lists existing (non-archived) account types from
// `accountTypeRepository.watchAll()` plus a footer "Create new account
// type" tile. Tapping the footer pushes a nested form whose controller
// delegates to `accountTypeRepository.save(...)`; the nested form is
// isolated from the outer account form so a save error there does not
// blow away the outer form's state (plan §12 risk #5).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../data/models/account_type.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import 'account_type_display.dart';
import 'currency_picker_sheet.dart';

/// Opens the account-type picker sheet. Resolves with the selected
/// `AccountType` (including any newly-created-inline type), or null if
/// the user dismisses.
Future<AccountType?> showAccountTypePickerSheet(BuildContext context) {
  return showModalBottomSheet<AccountType>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.75,
      child: _AccountTypePickerSheet(),
    ),
  );
}

class _AccountTypePickerSheet extends ConsumerWidget {
  const _AccountTypePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(_accountTypesStreamProvider);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.accountsTypePickerTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (async) {
              AsyncData<List<AccountType>>(:final value) => _TypesList(
                types: value,
              ),
              AsyncError(:final error) => Center(child: Text('$error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _TypesList extends StatelessWidget {
  const _TypesList({required this.types});

  final List<AccountType> types;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView.builder(
      itemCount: types.length + 1,
      itemBuilder: (ctx, i) {
        if (i == types.length) {
          return ListTile(
            key: const ValueKey('accountTypePicker:createInline'),
            leading: const Icon(Icons.add),
            title: Text(l10n.accountsTypeCreateInlineCta),
            onTap: () async {
              final created = await _showCreateAccountTypeSheet(context);
              if (created != null && context.mounted) {
                Navigator.of(context).pop(created);
              }
            },
          );
        }
        final t = types[i];
        final color = colorForIndex(t.color);
        return ListTile(
          key: ValueKey('accountTypePicker:${t.id}'),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(iconForKey(t.icon), color: color, size: 20),
          ),
          title: Text(accountTypeDisplayName(t, l10n)),
          onTap: () => Navigator.of(context).pop(t),
        );
      },
    );
  }
}

// ---------- Inline "create account type" form ----------

Future<AccountType?> _showCreateAccountTypeSheet(BuildContext context) {
  return showModalBottomSheet<AccountType>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: const _CreateAccountTypeForm(),
    ),
  );
}

class _CreateAccountTypeForm extends ConsumerStatefulWidget {
  const _CreateAccountTypeForm();

  @override
  ConsumerState<_CreateAccountTypeForm> createState() =>
      _CreateAccountTypeFormState();
}

class _CreateAccountTypeFormState
    extends ConsumerState<_CreateAccountTypeForm> {
  late final TextEditingController _nameCtrl;
  final String _icon = 'wallet';
  final int _color = 10; // neutralVariant70 per PRD default for seeded types
  Currency? _defaultCurrency;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => !_saving && _nameCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(accountTypeRepositoryProvider);
      final draft = AccountType(
        id: 0,
        customName: name,
        icon: _icon,
        color: _color,
        defaultCurrency: _defaultCurrency,
      );
      final id = await repo.save(draft);
      // Re-read so we return the row with its assigned id.
      final saved = await repo.getById(id);
      if (mounted && saved != null) Navigator.of(context).pop(saved);
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
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.accountsTypeFormTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('accountTypeForm:name'),
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.accountsTypeFormName,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  l10n.accountsTypeFormDefaultCurrency,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  key: const ValueKey('accountTypeForm:currency'),
                  onPressed: _saving
                      ? null
                      : () async {
                          final picked = await showCurrencyPickerSheet(context);
                          if (picked != null) {
                            setState(() => _defaultCurrency = picked);
                          }
                        },
                  child: Text(
                    _defaultCurrency?.code ?? l10n.accountsFormPickCurrency,
                  ),
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
                    color: Theme.of(context).colorScheme.onErrorContainer,
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
                        : () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('accountTypeForm:save'),
                    onPressed: _canSave ? _save : null,
                    child: Text(l10n.commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Feature-local stream of non-archived account types. `autoDispose` so
// the picker frees its subscription on dismiss.
final _accountTypesStreamProvider =
    StreamProvider.autoDispose<List<AccountType>>((ref) {
      final repo = ref.watch(accountTypeRepositoryProvider);
      return repo.watchAll();
    });

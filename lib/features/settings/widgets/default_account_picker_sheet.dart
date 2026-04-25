// Default-account picker sheet (plan §7).
//
// SETTINGS-OWNED picker: lists non-archived accounts via
// `accountRepositoryProvider.watchAll(includeArchived: false)`. Tapping
// a row resolves the sheet with the selected account id via
// `Navigator.pop(id)`; the caller writes via `SettingsController`.
//
// Empty state shows a "Create account" CTA that routes to
// `/accounts/new` — never writes a null default (plan §7).
//
// Deliberately does not import Accounts' `showCurrencyPickerSheet`; per
// plan §9 + Wave 0 §2.5, picker sheets are intra-slice in MVP.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/account.dart';
import '../../../l10n/app_localizations.dart';
import '../settings_providers.dart';

/// Opens the default-account picker sheet and resolves with the selected
/// account id, or null if the user dismisses or taps the "Create account"
/// CTA (which navigates to `/accounts/new` before dismissing).
Future<int?> showDefaultAccountPickerSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.75,
      child: _DefaultAccountPickerSheet(),
    ),
  );
}

class _DefaultAccountPickerSheet extends ConsumerWidget {
  const _DefaultAccountPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(settingsActiveAccountsProvider);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.settingsDefaultAccountPickerTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (async) {
              AsyncData<List<Account>>(:final value) => value.isEmpty
                  ? _EmptyState(
                      onCreate: () {
                        Navigator.of(context).pop();
                        context.go('/accounts/new');
                      },
                    )
                  : ListView.builder(
                      itemCount: value.length,
                      itemBuilder: (ctx, i) {
                        final a = value[i];
                        return ListTile(
                          key: ValueKey(
                            'defaultAccountOption:${a.id}',
                          ),
                          title: Text(a.name),
                          subtitle: Text(a.currency.code),
                          onTap: () => Navigator.of(context).pop(a.id),
                        );
                      },
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.accountsEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.settingsDefaultAccountCreateCta),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

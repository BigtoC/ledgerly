// Default-currency picker sheet (plan §8).
//
// SETTINGS-OWNED picker: lists non-token currencies via
// `currencyRepositoryProvider.watchAll()` filtered on `!isToken` (plan
// §13 risk #5 — Phase 2 tokens stay out of MVP). Tapping a row resolves
// the sheet with the selected currency code via `Navigator.pop(code)`.
//
// Deliberately does not import Accounts' `showCurrencyPickerSheet`; per
// plan §9 + Wave 0 §2.5, picker sheets are intra-slice in MVP.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/repository_providers.dart';
import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';

/// Opens the default-currency picker sheet and resolves with the chosen
/// ISO code, or null if the user dismisses.
Future<String?> showDefaultCurrencyPickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.75,
      child: _DefaultCurrencyPickerSheet(),
    ),
  );
}

class _DefaultCurrencyPickerSheet extends ConsumerWidget {
  const _DefaultCurrencyPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(_fiatCurrenciesStreamProvider);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.settingsDefaultCurrencyPickerTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Expanded(
            child: switch (async) {
              AsyncData<List<Currency>>(:final value) => ListView.builder(
                itemCount: value.length,
                itemBuilder: (ctx, i) {
                  final c = value[i];
                  return ListTile(
                    key: ValueKey('defaultCurrencyOption:${c.code}'),
                    leading: Text(
                      c.symbol ?? c.code,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    title: Text(c.code),
                    subtitle: Text(_displayName(c)),
                    onTap: () => Navigator.of(context).pop(c.code),
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

  /// Minimal display-name resolver — prefers `customName`, then falls back
  /// to the ISO code. MVP ships no per-currency l10n mapping table; the
  /// code alone is sufficient in all seeded locales.
  String _displayName(Currency c) {
    final custom = c.customName;
    if (custom != null && custom.trim().isNotEmpty) return custom;
    return c.code;
  }
}

// Feature-local stream of non-token currencies. Not promoted to a
// shared provider — Settings owns its own picker per plan §8.
final _fiatCurrenciesStreamProvider =
    StreamProvider.autoDispose<List<Currency>>((ref) {
  final repo = ref.watch(currencyRepositoryProvider);
  return repo.watchAll().map(
    (rows) => rows.where((c) => !c.isToken).toList(growable: false),
  );
});

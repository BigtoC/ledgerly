// Currency picker sheet (plan §5, §8).
//
// Owned by the Accounts slice for MVP. Lists non-token currencies from
// `currencyRepository.watchAll()`; selection resolves back to the
// caller via `Navigator.pop(currency)`. No side-effect on user
// preferences — the Accounts form uses this sheet to choose the
// currency for the account being edited, not the app-wide default
// (plan §8 closing note).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../accounts_providers.dart';
import 'currency_display.dart';

/// Opens the currency picker sheet and resolves with the user's
/// selection, or null if the sheet is dismissed.
Future<Currency?> showCurrencyPickerSheet(BuildContext context) {
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.75,
      child: _CurrencyPickerSheet(),
    ),
  );
}

class _CurrencyPickerSheet extends ConsumerWidget {
  const _CurrencyPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(selectableCurrenciesProvider);
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.accountsCurrencyPickerTitle,
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
                    key: ValueKey('currencyPicker:${c.code}'),
                    leading: Text(
                      c.symbol ?? c.code,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    title: Text(c.code),
                    subtitle: Text(currencyDisplayName(c, l10n)),
                    onTap: () => Navigator.of(context).pop(c),
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

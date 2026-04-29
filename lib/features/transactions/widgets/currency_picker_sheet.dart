// `showTxCurrencyPickerSheet` — Chunk 4 Task 8 Step 5.
//
// Transaction-form currency picker with search. Imports
// `selectableCurrenciesProvider` from the Accounts slice (shared SSOT).
// Returns the selected Currency, or null on dismiss.
//
// Differs from `accounts/widgets/currency_picker_sheet.dart` by adding:
//   - search TextField (autofocus, filters by code or localized name)
//   - no-results message when search matches nothing
//   - `isScrollControlled: true` so the list is not hidden behind the IME

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/currency.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/accounts_providers.dart';
import '../../accounts/widgets/currency_display.dart';

/// Opens the transaction currency picker sheet and resolves with the
/// user's selection, or null if the sheet is dismissed.
Future<Currency?> showTxCurrencyPickerSheet(BuildContext context) {
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.85,
      child: _TxCurrencyPickerSheet(),
    ),
  );
}

class _TxCurrencyPickerSheet extends ConsumerStatefulWidget {
  const _TxCurrencyPickerSheet();

  @override
  ConsumerState<_TxCurrencyPickerSheet> createState() =>
      _TxCurrencyPickerSheetState();
}

class _TxCurrencyPickerSheetState
    extends ConsumerState<_TxCurrencyPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Currency> _filter(List<Currency> currencies, AppLocalizations l10n) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return currencies;
    return currencies
        .where((c) {
          final name = currencyDisplayName(c, l10n).toLowerCase();
          return c.code.toLowerCase().contains(q) || name.contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(selectableCurrenciesProvider);

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.txCurrencyPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.txCurrencySearchHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          // Currency list
          Expanded(
            child: switch (async) {
              AsyncData<List<Currency>>(:final value) => _buildList(
                context,
                l10n,
                _filter(value, l10n),
              ),
              AsyncError(:final error) => Center(
                child: Text('Could not load currencies: $error'),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    List<Currency> filtered,
  ) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.txCurrencyPickerNoResults),
        ),
      );
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final c = filtered[i];
        return ListTile(
          key: ValueKey('txCurrencyPicker:${c.code}'),
          leading: Text(
            c.symbol ?? c.code,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          title: Text(c.code),
          subtitle: Text(currencyDisplayName(c, l10n)),
          onTap: () => Navigator.of(context).pop(c),
        );
      },
    );
  }
}

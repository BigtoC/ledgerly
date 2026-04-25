// `showAccountPickerSheet` — Wave 2 §4.1.
//
// Adaptive sheet listing non-archived accounts. Mirrors the Wave 1
// settings-picker shell: bottom sheet on <600dp, constrained dialog on
// >=600dp so the form does not stack an unbounded phone sheet inside
// the tablet dialog (Wave 2 §8 adaptive container rule).
//
// Returns the selected `Account`, or `null` when the user dismisses.
// Caller decides whether the swap requires a currency-change confirm
// dialog (Wave 2 risk #9) before applying the result.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/account.dart';
import '../../../l10n/app_localizations.dart';
import '../transactions_providers.dart';

Future<Account?> showAccountPickerSheet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<Account>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: const _AccountPickerSheet(),
        ),
      ),
    );
  }
  return showModalBottomSheet<Account>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.6,
      child: _AccountPickerSheet(),
    ),
  );
}

class _AccountPickerSheet extends ConsumerWidget {
  const _AccountPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(txActiveAccountsProvider);
    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.txAccountPickerTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ...switch (async) {
            AsyncData<List<Account>>(:final value) when value.isEmpty => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.txAccountEmpty),
                  ),
                ),
              ),
            ],
            AsyncData<List<Account>>(:final value) => [
              SliverList.builder(
                itemCount: value.length,
                itemBuilder: (context, i) {
                  final account = value[i];
                  return ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(account.name),
                    trailing: Text(account.currency.code),
                    onTap: () => Navigator.of(context).pop(account),
                  );
                },
              ),
            ],
            AsyncError(:final error) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('$error')),
              ),
            ],
            _ => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

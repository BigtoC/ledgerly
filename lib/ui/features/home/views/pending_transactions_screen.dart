// Settings › Pending transactions (issue #71).
//
// Lists every pending row, from every day, with Home's PendingTile:
// approve with the circle, skip with swipe-left and a 4-second undo. The
// snackbars come from PendingSnackBars, mounted above the shell.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../view_models/home_providers.dart';
import '../view_models/pending_controller.dart';
import '../view_models/pending_state.dart';
import 'pending_section.dart';

@Dependencies([PendingController])
class PendingTransactionsScreen extends ConsumerWidget {
  const PendingTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(pendingControllerProvider.notifier);
    final categories = ref.watch(homeCategoriesByIdProvider).value ?? const {};
    final accounts = ref.watch(homeAccountsByIdProvider).value ?? const {};
    final locale = Localizations.localeOf(context).toString();
    final empty = Center(child: Text(l10n.pendingTransactionsEmpty));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pendingTransactionsTitle)),
      body: SlidableAutoCloseBehavior(
        child: switch (ref.watch(pendingControllerProvider)) {
          AsyncData(value: PendingError()) ||
          AsyncError() => Center(child: Text(l10n.homePendingLoadError)),
          AsyncData(value: PendingEmpty()) => empty,
          // Rows keep the repository's order: newest date first.
          AsyncData(value: final PendingData data) => switch (data.visibleOn(
            null,
          )) {
            [] => empty,
            final rows => ListView.builder(
              itemCount: rows.length,
              // Lets a row keep its state (approve in flight, open
              // Slidable) when a row above it leaves.
              findChildIndexCallback: (key) {
                final i = rows.indexWhere((r) => ValueKey(r.id) == key);
                return i < 0 ? null : i;
              },
              itemBuilder: (_, i) {
                final item = rows[i];
                return PendingTile(
                  key: ValueKey(item.id),
                  item: item,
                  category: categories[item.categoryId],
                  account: accounts[item.accountId],
                  locale: locale,
                  onApprove: () => notifier.approve(item.id),
                  onSkip: () => unawaited(notifier.skip(item.id)),
                );
              },
            ),
          },
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

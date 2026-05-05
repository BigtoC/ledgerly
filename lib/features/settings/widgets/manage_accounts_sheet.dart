import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../accounts/accounts_controller.dart';
import '../../accounts/accounts_state.dart';
import '../../accounts/widgets/manage_accounts_body.dart';
import '../../../l10n/app_localizations.dart';

/// Opens the Manage accounts surface and returns when the user dismisses it.
Future<void> showManageAccountsSheet(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 600) {
    return showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: const _ManageAccountsContent(),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    builder: (ctx) => const FractionallySizedBox(
      heightFactor: 0.75,
      child: _ManageAccountsContent(),
    ),
  );
}

class _ManageAccountsContent extends ConsumerWidget {
  const _ManageAccountsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(accountsControllerProvider);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.manageAccountsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          Flexible(
            child: switch (state) {
              AsyncData<AccountsState>(value: final AccountsData data) =>
                ManageAccountsBody(data: data),
              AsyncData<AccountsState>(value: AccountsError()) ||
              AsyncError() => _ErrorPlaceholder(
                onRetry: () => ref.invalidate(accountsControllerProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.manageAccountsCreateCta),
                onPressed: () => context.push('/settings/manage-accounts/new'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.manageAccountsLoadError,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.shoppingListScreenRetry),
            ),
          ],
        ),
      ),
    );
  }
}

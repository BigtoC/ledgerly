// ShoppingListCard — preview card shown on the Accounts screen.
//
// Always visible; renders newest 3 drafts from shoppingListPreviewProvider.
// Tap on a row or the "View all" CTA navigates to /accounts/shopping-list.
// Empty-state CTA navigates to /home/add (push).
//
// No swipe actions — tap only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/utils/box_shadow.dart';
import '../../../data/models/shopping_list_item.dart';
import '../../../l10n/app_localizations.dart';
import '../shopping_list_item_labels.dart';
import '../shopping_list_providers.dart';

class ShoppingListCard extends ConsumerWidget {
  const ShoppingListCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final previewAsync = ref.watch(shoppingListPreviewProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(homePageCardBorderRadius),
        boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 4, top: 4, bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.shoppingListCardTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('shoppingListCardAddButton'),
                    icon: const Icon(Icons.add),
                    tooltip: l10n.shoppingListEmptyCta,
                    onPressed: () => context.push('/home/add'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/accounts/shopping-list'),
                    child: Text(l10n.shoppingListViewAll),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Body ────────────────────────────────────────────────────
            previewAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => InkWell(
                onTap: () => context.go('/accounts/shopping-list'),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.errorSnackbarGeneric)),
                ),
              ),
              data: (data) {
                final (:preview, :totalCount) = data;
                if (preview.isEmpty) {
                  return _EmptyBody(l10n: l10n);
                }
                final overflowCount = totalCount > 3 ? totalCount - 3 : 0;
                return Column(
                  children: [
                    for (final item in preview) _PreviewRow(item: item),
                    if (overflowCount > 0)
                      _OverflowCta(count: overflowCount, l10n: l10n),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.shoppingListEmptyBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => context.push('/home/add'),
            child: Text(l10n.shoppingListEmptyCta),
          ),
        ],
      ),
    );
  }
}

// ── Overflow CTA ───────────────────────────────────────────────────────────

class _OverflowCta extends StatelessWidget {
  const _OverflowCta({required this.count, required this.l10n});

  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/accounts/shopping-list'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Center(
          child: Text(
            l10n.shoppingListItemsMore(count),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

// ── Preview row ────────────────────────────────────────────────────────────

class _PreviewRow extends ConsumerWidget {
  const _PreviewRow({required this.item});

  final ShoppingListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoryAsync = ref.watch(
      shoppingListCategoryByIdProvider(item.categoryId),
    );
    final accountAsync = ref.watch(
      shoppingListAccountByIdProvider(item.accountId),
    );

    final currencyAsync = item.draftCurrencyCode != null
        ? ref.watch(shoppingListCurrencyByCodeProvider(item.draftCurrencyCode!))
        : null;

    final category = categoryAsync.valueOrNull;
    final account = accountAsync.valueOrNull;
    final currency = currencyAsync?.valueOrNull;

    final locale = Localizations.localeOf(context).toString();
    final primaryLabel = resolvePrimaryLabel(item, category, l10n);
    final secondaryLabel = resolveSecondaryLabel(category, account, l10n);
    final trailingLabel = resolveTrailingLabel(item, currency, locale);

    return InkWell(
      onTap: () => context.go('/accounts/shopping-list'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (secondaryLabel.isNotEmpty)
                    Text(
                      secondaryLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailingLabel.isNotEmpty)
              Text(trailingLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

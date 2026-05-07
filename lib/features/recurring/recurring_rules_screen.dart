// Recurring rules management screen.
//
// Pure projection of [RecurringRulesController] into the standard
// loading / empty / data / error UI states. Delete uses swipe-to-delete
// + 4-second undo (mirrors ShoppingListScreen).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants.dart';
import '../../data/models/recurring_rule.dart';
import '../../l10n/app_localizations.dart';
import 'recurring_rules_controller.dart';
import 'recurring_rules_state.dart';

class RecurringRulesScreen extends ConsumerStatefulWidget {
  const RecurringRulesScreen({super.key});

  @override
  ConsumerState<RecurringRulesScreen> createState() =>
      _RecurringRulesScreenState();
}

class _RecurringRulesScreenState extends ConsumerState<RecurringRulesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref
          .read(recurringRulesControllerProvider.notifier)
          .setEffectListener(_onEffect);
    });
  }

  @override
  void dispose() {
    ref.read(recurringRulesControllerProvider.notifier).setEffectListener(null);
    super.dispose();
  }

  void _onEffect(RecurringRulesEffect effect) {
    if (!mounted) return;
    if (effect is RecurringRulesDeleteFailedEffect) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delete failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncState = ref.watch(recurringRulesControllerProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringRulesTitle),
        actions: [
          if (isWide)
            IconButton(
              tooltip: l10n.recurringFabNew,
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/settings/recurring/new'),
            ),
        ],
      ),
      floatingActionButton: isWide
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/settings/recurring/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.recurringFabNew),
            ),
      body: SlidableAutoCloseBehavior(
        child: switch (asyncState) {
          AsyncData(value: RecurringRulesLoading()) ||
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncData(value: RecurringRulesEmpty()) => _EmptyState(l10n: l10n),
          AsyncData(value: RecurringRulesData(:final rules)) => _RuleList(
            rules: rules,
          ),
          AsyncData(value: RecurringRulesError()) ||
          AsyncError() => _ErrorState(l10n: l10n),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _RuleList extends ConsumerWidget {
  const _RuleList({required this.rules});

  final List<RecurringRule> rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(recurringRulesControllerProvider.notifier);
    return ListView.builder(
      itemCount: rules.length,
      itemBuilder: (ctx, i) {
        final rule = rules[i];
        return _RuleTile(
          key: ValueKey('recurringRuleTile:${rule.id}'),
          rule: rule,
          onTap: () => context.push('/settings/recurring/${rule.id}'),
          onPause: () async {
            await controller.pauseRule(rule.id);
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(l10n.recurringPausedSnack(rule.name))),
            );
          },
          onResume: () async {
            await controller.resumeRule(rule.id);
            if (!ctx.mounted) return;
            final updated = rules.firstWhere(
              (r) => r.id == rule.id,
              orElse: () => rule,
            );
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.recurringResumedSnack(
                    rule.name,
                    DateFormat.yMMMd().format(updated.nextDueDate),
                  ),
                ),
              ),
            );
          },
          onDelete: () async {
            await controller.deleteRule(rule.id);
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(l10n.recurringDeletedSnack),
                action: SnackBarAction(
                  label: l10n.commonUndo,
                  onPressed: controller.undoDelete,
                ),
                duration: kUndoWindow,
              ),
            );
          },
        );
      },
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    super.key,
    required this.rule,
    required this.onTap,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  final RecurringRule rule;
  final VoidCallback onTap;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dueText = l10n.recurringTileNextDue(
      DateFormat.yMMMd().format(rule.nextDueDate),
    );
    final inactive = !rule.isActive;
    final tile = Opacity(
      opacity: inactive ? 0.6 : 1.0,
      child: ListTile(
        title: Text(rule.name),
        subtitle: Text(dueText),
        trailing: inactive
            ? Chip(
                label: Text(l10n.recurringTilePaused),
                visualDensity: VisualDensity.compact,
              )
            : (rule.lastError != null
                  ? Tooltip(
                      message: l10n.recurringRuleHasError,
                      child: Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                      ),
                    )
                  : null),
        onTap: onTap,
      ),
    );

    return Slidable(
      key: ValueKey('recurringRuleSlidable:${rule.id}'),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => inactive ? onResume() : onPause(),
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            icon: inactive ? Icons.play_arrow : Icons.pause,
            label: inactive
                ? l10n.recurringSwipeResume
                : l10n.recurringSwipePause,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            icon: Icons.delete,
            label: l10n.recurringSwipeDelete,
          ),
        ],
      ),
      child: tile,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.recurringEmptyHeading,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.recurringEmptyBody,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  GoRouter.of(context).push('/settings/recurring/new'),
              child: Text(l10n.recurringEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.recurringRulesLoadError),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(recurringRulesControllerProvider),
              child: Text(l10n.recurringRulesLoadRetry),
            ),
          ],
        ),
      ),
    );
  }
}

// Home screen — Wave 3 §4.1, §11.
//
// Layout (PRD → Layout Primitives → Home):
//   Scaffold
//     └─ CustomScrollView
//         ├─ SliverToBoxAdapter — summary strip (currency-grouped)
//         ├─ SliverToBoxAdapter — day-nav header (prev ◀ {label} ▶ next)
//         ├─ SliverList — TransactionTile per row (reverse-chronological)
//         └─ SliverPadding — FAB clearance
//
// Adaptive: <600dp single-pane sliver; >=600dp two-pane (left activity
// chooser, right selected-day detail). First-run empty spans the full
// content region.
//
// Delete + undo: swipe-to-delete and overflow→Delete both call
// `controller.deleteTransaction(id)`, which schedules a 4-second timer
// (Wave 3 §8). The screen surfaces the SnackBar; the action button
// fires `controller.undoDelete()`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_helpers.dart';
import '../../data/models/transaction.dart';
import '../../l10n/app_localizations.dart';
import 'home_controller.dart';
import 'home_providers.dart';
import 'home_state.dart';
import 'widgets/day_navigation_header.dart';
import 'widgets/summary_strip.dart';
import 'widgets/transaction_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  PendingDelete? _lastShownPending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(homeControllerProvider);

    // Auto-pin the day after a save round-trip from the form: the
    // route push returns a `Transaction`; we rely on
    // `controller.pinDay(savedTx.date)` from the FAB / row-tap call
    // sites below.

    // Surface SnackBar on pendingDelete transitions (null → set).
    ref.listen(homeControllerProvider, (_, next) {
      if (next is AsyncData<HomeState>) {
        final value = next.value;
        if (value is HomeData) {
          _maybeShowUndoSnackbar(context, value.pendingDelete);
        }
      }
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddPressed(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.homeFabLabel),
      ),
      body: SlidableAutoCloseBehavior(
        child: switch (state) {
          AsyncData<HomeState>(value: final HomeData data) => _AdaptiveBody(
            data: data,
            onPrev: () =>
                ref.read(homeControllerProvider.notifier).selectPrevDay(),
            onNext: () =>
                ref.read(homeControllerProvider.notifier).selectNextDay(),
            onPickDay: (day) => _onPickDay(day, data),
            onTapRow: _onEditRow,
            onDuplicateRow: _onDuplicateRow,
            onDeleteRow: (id) =>
                ref.read(homeControllerProvider.notifier).deleteTransaction(id),
          ),
          AsyncData<HomeState>(value: HomeEmpty()) => _EmptyState(
            onAdd: () => _onAddPressed(context),
          ),
          AsyncData<HomeState>(value: HomeError()) ||
          AsyncError() => _ErrorSurface(message: l10n.errorSnackbarGeneric),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Future<void> _onAddPressed(BuildContext context) async {
    final saved = await context.push<Transaction>('/home/add');
    if (saved != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(saved.date);
    }
  }

  Future<void> _onEditRow(int id) async {
    final saved = await context.push<Transaction>('/home/edit/$id');
    if (saved != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(saved.date);
    }
  }

  Future<void> _onDuplicateRow(int id) async {
    final saved = await context.push<Transaction>(
      '/home/add',
      extra: <String, Object>{'duplicateSourceId': id},
    );
    if (saved != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(saved.date);
    }
  }

  Future<void> _onPickDay(DateTime initial, HomeData data) async {
    // Range: oldest activity day .. today + 30d (PRD allows manual
    // future gap-day navigation).
    final today = DateHelpers.startOfDay(DateTime.now());
    final firstDate =
        data.prevDayWithActivity ??
        (data.transactionsForDay.isNotEmpty ? data.selectedDay : today);
    final lastDate = today.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: data.selectedDay,
      firstDate: firstDate.isBefore(initial) ? firstDate : initial,
      lastDate: lastDate,
    );
    if (picked != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(picked);
    }
  }

  void _maybeShowUndoSnackbar(BuildContext context, PendingDelete? pending) {
    final l10n = AppLocalizations.of(context);
    if (pending == null) {
      _lastShownPending = null;
      return;
    }
    if (identical(pending, _lastShownPending)) return;
    _lastShownPending = pending;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.homeDeleteUndoSnackbar),
          duration: kUndoWindow,
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () {
              ref.read(homeControllerProvider.notifier).undoDelete();
            },
          ),
        ),
      );
  }
}

class _AdaptiveBody extends ConsumerWidget {
  const _AdaptiveBody({
    required this.data,
    required this.onPrev,
    required this.onNext,
    required this.onPickDay,
    required this.onTapRow,
    required this.onDuplicateRow,
    required this.onDeleteRow,
  });

  final HomeData data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime initial) onPickDay;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _SinglePane(
            data: data,
            onPrev: onPrev,
            onNext: onNext,
            onPickDay: onPickDay,
            onTapRow: onTapRow,
            onDuplicateRow: onDuplicateRow,
            onDeleteRow: onDeleteRow,
          );
        }
        return _TwoPane(
          data: data,
          onPrev: onPrev,
          onNext: onNext,
          onPickDay: onPickDay,
          onTapRow: onTapRow,
          onDuplicateRow: onDuplicateRow,
          onDeleteRow: onDeleteRow,
        );
      },
    );
  }
}

class _SinglePane extends ConsumerWidget {
  const _SinglePane({
    required this.data,
    required this.onPrev,
    required this.onNext,
    required this.onPickDay,
    required this.onTapRow,
    required this.onDuplicateRow,
    required this.onDeleteRow,
  });

  final HomeData data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime initial) onPickDay;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toString();
    final currencies =
        ref.watch(homeCurrenciesByCodeProvider).valueOrNull ?? const {};
    final categories =
        ref.watch(homeCategoriesByIdProvider).valueOrNull ?? const {};
    final accounts =
        ref.watch(homeAccountsByIdProvider).valueOrNull ?? const {};
    final l10n = AppLocalizations.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SummaryStrip(
            todayTotalsByCurrency: data.todayTotalsByCurrency,
            monthNetByCurrency: data.monthNetByCurrency,
            currenciesByCode: currencies,
            locale: locale,
          ),
        ),
        SliverToBoxAdapter(
          child: DayNavigationHeader(
            selectedDay: data.selectedDay,
            locale: locale,
            onPrev: onPrev,
            onNext: onNext,
            onPickDay: () => onPickDay(data.selectedDay),
            canGoPrev: data.prevDayWithActivity != null,
            canGoNext: data.nextDayWithActivity != null,
          ),
        ),
        if (data.transactionsForDay.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.homeDayEmptyTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) {
              final tx = data.transactionsForDay[i];
              return TransactionTile(
                transaction: tx,
                category: categories[tx.categoryId],
                account: accounts[tx.accountId],
                locale: locale,
                onTap: () => onTapRow(tx.id),
                onDuplicate: () => onDuplicateRow(tx.id),
                onDelete: () => onDeleteRow(tx.id),
              );
            }, childCount: data.transactionsForDay.length),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _TwoPane extends ConsumerWidget {
  const _TwoPane({
    required this.data,
    required this.onPrev,
    required this.onNext,
    required this.onPickDay,
    required this.onTapRow,
    required this.onDuplicateRow,
    required this.onDeleteRow,
  });

  final HomeData data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime initial) onPickDay;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: _ActivityPane(data: data, onPickDay: onPickDay),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _SinglePane(
            data: data,
            onPrev: onPrev,
            onNext: onNext,
            onPickDay: onPickDay,
            onTapRow: onTapRow,
            onDuplicateRow: onDuplicateRow,
            onDeleteRow: onDeleteRow,
          ),
        ),
      ],
    );
  }
}

class _ActivityPane extends ConsumerWidget {
  const _ActivityPane({required this.data, required this.onPickDay});

  final HomeData data;
  final void Function(DateTime initial) onPickDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Render the prev/next chain as a vertical list of days starting
    // from the selected day. We expose the manual date picker in the
    // header so the user can jump anywhere even when the activity list
    // is short.
    final days = <DateTime>[
      if (data.nextDayWithActivity != null) data.nextDayWithActivity!,
      data.selectedDay,
      if (data.prevDayWithActivity != null) data.prevDayWithActivity!,
    ];
    final locale = Localizations.localeOf(context).toString();
    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (ctx, i) {
        final day = days[i];
        final isSelected = DateHelpers.isSameDay(day, data.selectedDay);
        return ListTile(
          selected: isSelected,
          title: Text(DateHelpers.formatDayHeader(day, locale)),
          onTap: () => onPickDay(day),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

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
              l10n.homeEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(l10n.homeEmptyCta),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSurface extends StatelessWidget {
  const _ErrorSurface({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

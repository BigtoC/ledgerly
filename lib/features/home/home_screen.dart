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

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/box_shadow.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/models/account.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../l10n/app_localizations.dart';
import '../../core/constants.dart';
import 'home_controller.dart';
import 'home_providers.dart';
import 'home_state.dart';
import 'widgets/day_navigation_header.dart';
import 'widgets/pending_badge.dart';
import 'widgets/summary_strip.dart';
import 'widgets/transaction_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _kDaySwitchDuration = Duration(milliseconds: 280);
  static const _kDaySwitchCurve = Curves.easeInOut;

  PendingDelete? _lastShownPending;
  late final HomeController _controller;
  late final AnimationController _daySwitchController;
  late Animation<Offset> _incomingOffset;
  final Queue<int> _directionQueue = Queue<int>();
  int _activeDirection = 0; // -1 older, +1 newer
  DateTime? _visibleDay;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(homeControllerProvider.notifier);
    _controller.setEffectListener(_onEffect);
    _daySwitchController = AnimationController(
      duration: _kDaySwitchDuration,
      vsync: this,
    );
    _incomingOffset = _buildOffsetAnimation(0);
    _daySwitchController.value = 1.0; // start fully visible
  }

  @override
  void dispose() {
    _daySwitchController.dispose();
    _controller.setEffectListener(null);
    super.dispose();
  }

  Animation<Offset> _buildOffsetAnimation(int direction) {
    // direction +1 = newer day, slides in from right
    // direction -1 = older day, slides in from left
    final begin = direction >= 0
        ? const Offset(1.0, 0.0)
        : const Offset(-1.0, 0.0);
    return Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _daySwitchController, curve: _kDaySwitchCurve),
    );
  }

  void _enqueueDayStep(int delta) {
    // Cap the queue at 5 to prevent long drain after user stops interacting
    if (_directionQueue.length >= 5) return;
    _directionQueue.add(delta > 0 ? 1 : -1);
    if (!_daySwitchController.isAnimating) {
      _runNextQueuedStep();
    }
  }

  Future<void> _runNextQueuedStep() async {
    if (_directionQueue.isEmpty) return;
    final direction = _directionQueue.removeFirst();
    _activeDirection = direction;
    _incomingOffset = _buildOffsetAnimation(direction);

    if (direction > 0) {
      await ref.read(homeControllerProvider.notifier).selectNextDay();
    } else {
      await ref.read(homeControllerProvider.notifier).selectPrevDay();
    }

    _daySwitchController.reset();
    await _daySwitchController.forward();

    if (_directionQueue.isNotEmpty) {
      unawaited(_runNextQueuedStep());
    }
  }

  Future<void> _jumpToDay(DateTime pickedDay) async {
    final current = _visibleDay;
    if (current != null && DateHelpers.isSameDay(pickedDay, current)) return;

    _activeDirection = (current == null || pickedDay.isAfter(current)) ? 1 : -1;
    _incomingOffset = _buildOffsetAnimation(_activeDirection);

    await ref.read(homeControllerProvider.notifier).pinDay(pickedDay);
    _daySwitchController.reset();
    await _daySwitchController.forward();
  }

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
        tooltip: l10n.homeFabLabel,
      ),
      body: SlidableAutoCloseBehavior(
        child: switch (state) {
          AsyncData<HomeState>(value: final HomeData data) => _AdaptiveBody(
            data: data,
            onPrev: () => _enqueueDayStep(-1),
            onNext: () => _enqueueDayStep(1),
            onPickDay: (day) => _onPickDay(day, data),
            onTapRow: _onEditRow,
            onDuplicateRow: _onDuplicateRow,
            onDeleteRow: (id) =>
                ref.read(homeControllerProvider.notifier).deleteTransaction(id),
            daySwitchAnimation: _incomingOffset,
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
    // Carry the currently selected day to the form so the date field
    // matches what the user is looking at on Home. The form falls back
    // to today when `initialDate` is absent from the route extra.
    final selectedDay = _selectedDayForAdd();
    final saved = await context.push<Transaction>(
      '/home/add',
      extra: selectedDay == null
          ? null
          : <String, Object>{'initialDate': selectedDay},
    );
    if (!mounted) return;
    if (saved != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(saved.date);
    }
  }

  DateTime? _selectedDayForAdd() {
    final s = ref.read(homeControllerProvider);
    if (s is AsyncData<HomeState>) {
      final v = s.value;
      if (v is HomeData) return v.selectedDay;
      if (v is HomeEmpty) return v.selectedDay;
    }
    return null;
  }

  Future<void> _onEditRow(int id) async {
    final saved = await context.push<Transaction>('/home/edit/$id');
    if (!mounted) return;
    if (saved != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(saved.date);
    }
  }

  Future<void> _onDuplicateRow(int id) async {
    final saved = await context.push<Transaction>(
      '/home/add',
      extra: <String, Object>{'duplicateSourceId': id},
    );
    if (!mounted) return;
    if (saved != null) {
      await ref.read(homeControllerProvider.notifier).pinDay(saved.date);
    }
  }

  Future<void> _onPickDay(DateTime initial, HomeData data) async {
    // Cap the date picker to [DateTime(1900), today] — consistent with
    // _minSelectableDay in HomeController and the prev/next boundaries.
    // No future dates: users cannot pre-enter future transactions via
    // the Home date picker.
    final picked = await showDatePicker(
      context: context,
      initialDate: data.selectedDay,
      firstDate: DateTime(1900),
      lastDate: data.today,
    );
    if (!mounted) return;
    if (picked != null) {
      await _jumpToDay(picked);
    }
  }

  void _maybeShowUndoSnackbar(BuildContext context, PendingDelete? pending) {
    final l10n = AppLocalizations.of(context);
    if (pending == null) {
      _lastShownPending = null;
      return;
    }
    if (_lastShownPending?.transaction.id == pending.transaction.id) return;
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

  void _onEffect(HomeEffect effect) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);

    switch (effect) {
      case HomeDeleteFailedEffect():
        messenger
          ?..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
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
    this.daySwitchAnimation,
  });

  final HomeData data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime initial) onPickDay;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;
  final Animation<Offset>? daySwitchAnimation;

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
            daySwitchAnimation: daySwitchAnimation,
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
          daySwitchAnimation: daySwitchAnimation,
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
    this.daySwitchAnimation,
  });

  final HomeData data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime initial) onPickDay;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;
  final Animation<Offset>? daySwitchAnimation;

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
    const double transactionPadding = 24;

    Widget dayContent;
    if (data.transactionsForDay.isEmpty) {
      dayContent = SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
          padding: const EdgeInsets.all(transactionPadding),
          child: Center(
            child: Text(
              l10n.homeEmptyDayMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    } else {
      dayContent = SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: homePageCardHorizontalPadding - transactionPadding,
          vertical: 12,
        ),
        sliver: SliverToBoxAdapter(
          child: _TransactionListCard(
            transactions: data.transactionsForDay,
            categories: categories,
            accounts: accounts,
            locale: locale,
            onTapRow: onTapRow,
            onDuplicateRow: onDuplicateRow,
            onDeleteRow: onDeleteRow,
          ),
        ),
      );
    }

    final animation = daySwitchAnimation;
    Widget dayBody = CustomScrollView(
      slivers: [
        dayContent,
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );

    if (animation != null) {
      dayBody = SlideTransition(
        position: animation,
        child: KeyedSubtree(
          key: ValueKey<DateTime>(data.selectedDay),
          child: dayBody,
        ),
      );
    }

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 38),
              SummaryStrip(
                todayTotalsByCurrency: data.todayTotalsByCurrency,
                monthNetByCurrency: data.monthNetByCurrency,
                currenciesByCode: currencies,
                locale: locale,
                showJumpToToday: !DateHelpers.isSameDay(
                  data.selectedDay,
                  data.today,
                ),
                onJumpToToday: () =>
                    ref.read(homeControllerProvider.notifier).selectToday(),
              ),
              DayNavigationHeader(
                selectedDay: data.selectedDay,
                locale: locale,
                onPrev: onPrev,
                onNext: onNext,
                onPickDay: () => onPickDay(data.selectedDay),
                canGoPrev: data.canGoPrev,
                canGoNext: data.canGoNext,
                trailing: PendingBadge(count: data.pendingBadgeCount),
              ),
            ],
          ),
        ),
        SliverFillRemaining(
          child: GestureDetector(
            // Horizontal flick → step prev/next day via animation queue.
            // Use pixelsPerSecond (Offset) not primaryVelocity (double?)
            // so the purity check (dx > dy) is possible.
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final dx = details.velocity.pixelsPerSecond.dx;
              final dy = details.velocity.pixelsPerSecond.dy;
              if (dx.abs() >= 300 && dx.abs() > dy.abs()) {
                // positive dx = finger moved right = older day (prev)
                // negative dx = finger moved left = newer day (next)
                if (dx > 0) {
                  onPrev();
                } else {
                  onNext();
                }
              }
            },
            child: dayBody,
          ),
        ),
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
    this.daySwitchAnimation,
  });

  final HomeData data;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final void Function(DateTime initial) onPickDay;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;
  final Animation<Offset>? daySwitchAnimation;

  Widget _buildLeftPane() => const SizedBox.shrink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        SizedBox(width: 280, child: _buildLeftPane()),
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
            daySwitchAnimation: daySwitchAnimation,
          ),
        ),
      ],
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

/// Rounded surface that wraps a single day's transaction rows. Mirrors
/// the summary-strip card styling (`homePageCardBorderRadius`,
/// `buildBoxShadow`, `surfaceContainer`) so the home page reads as a
/// stack of consistent cards. The list is rendered as a `Column` rather
/// than a sliver because a single day's row count is bounded; the
/// outer `CustomScrollView` still drives vertical scrolling.
class _TransactionListCard extends StatelessWidget {
  const _TransactionListCard({
    required this.transactions,
    required this.categories,
    required this.accounts,
    required this.locale,
    required this.onTapRow,
    required this.onDuplicateRow,
    required this.onDeleteRow,
  });

  final List<Transaction> transactions;
  final Map<int, Category> categories;
  final Map<int, Account> accounts;
  final String locale;
  final void Function(int id) onTapRow;
  final void Function(int id) onDuplicateRow;
  final void Function(int id) onDeleteRow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(homePageCardBorderRadius),
        boxShadow: [buildBoxShadow(homePageCardBorderRadius)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final tx in transactions)
            TransactionTile(
              transaction: tx,
              category: categories[tx.categoryId],
              account: accounts[tx.accountId],
              locale: locale,
              onTap: () => onTapRow(tx.id),
              onDuplicate: () => onDuplicateRow(tx.id),
              onDelete: () => onDeleteRow(tx.id),
            ),
        ],
      ),
    );
  }
}

// Pending approval section — spec 2026-05-08.
//
// Sliver mounted on HomeScreen above the transaction list. Watches
// `pendingControllerProvider` and renders a header + list of PendingTile
// widgets. Auto-hides when no pending rows exist.
//
// The Approve circle button owns a 200ms grey→green animation and
// debounces rapid taps. Swipe-left reveals a Skip action via
// flutter_slidable.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/utils/color_palette.dart';
import '../../../core/utils/icon_registry.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../data/models/account.dart';
import '../../../data/models/category.dart';
import '../../../data/models/pending_transaction.dart';
import '../../../l10n/app_localizations.dart';
import '../../categories/widgets/category_display.dart';
import '../home_providers.dart';
import '../pending_controller.dart';
import '../pending_state.dart';
import 'pending_badge.dart';

/// Maximum number of pending tiles to render before collapsing the rest
/// behind a "Show N more" expander. Bounds the worst case where a user
/// returns after a long absence with many overdue rules.
const int _kPendingCollapseThreshold = 5;

/// Sliver that renders the pending approval section on HomeScreen.
class PendingSection extends ConsumerStatefulWidget {
  const PendingSection({super.key});

  @override
  ConsumerState<PendingSection> createState() => _PendingSectionState();
}

class _PendingSectionState extends ConsumerState<PendingSection> {
  PendingController? _controller;
  bool _expanded = false;

  @override
  void dispose() {
    _controller?.setEffectListener(null);
    super.dispose();
  }

  void _bindController(PendingController controller) {
    if (_controller == controller) return;
    _controller?.setEffectListener(null);
    _controller = controller;
    controller.setEffectListener(_onEffect);
  }

  void _onEffect(PendingEffect effect) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    switch (effect) {
      case PendingSkipStartedEffect():
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.homePendingSkippedSnack),
              duration: kUndoWindow,
              action: SnackBarAction(
                label: l10n.commonUndo,
                onPressed: () {
                  ref.read(pendingControllerProvider.notifier).undoSkip();
                },
              ),
            ),
          );
      case PendingApproveSucceededEffect(:final ruleName):
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.homePendingApprovedSnack(ruleName))),
          );
      case PendingApproveFailedEffect():
      case PendingSkipFailedEffect():
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendingControllerProvider);

    return switch (state) {
      AsyncData<PendingState>(value: PendingLoading()) =>
        const SliverToBoxAdapter(child: SizedBox.shrink()),
      AsyncData<PendingState>(value: PendingEmpty()) =>
        const SliverToBoxAdapter(child: SizedBox.shrink()),
      AsyncData<PendingState>(value: PendingError()) => SliverToBoxAdapter(
        child: _ErrorBanner(
          message: AppLocalizations.of(context).homePendingLoadError,
        ),
      ),
      AsyncData<PendingState>(value: final PendingData data) => _buildData(
        context,
        data,
      ),
      _ => const SliverToBoxAdapter(child: SizedBox.shrink()),
    };
  }

  Widget _buildData(BuildContext context, PendingData data) {
    final notifier = ref.read(pendingControllerProvider.notifier);
    _bindController(notifier);

    final l10n = AppLocalizations.of(context);

    final skipId = data.skipScheduled?.pendingId;
    final visible = skipId == null
        ? data.items
        : data.items.where((item) => item.id != skipId).toList();

    if (visible.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final categories =
        ref.watch(homeCategoriesByIdProvider).valueOrNull ?? const {};
    final accounts =
        ref.watch(homeAccountsByIdProvider).valueOrNull ?? const {};
    final locale = Localizations.localeOf(context).toString();

    final overflowCount = visible.length - _kPendingCollapseThreshold;
    final showCollapseToggle = overflowCount > 0;
    final tilesToRender = (showCollapseToggle && !_expanded)
        ? visible.take(_kPendingCollapseThreshold).toList()
        : visible;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: homePageCardHorizontalPadding,
          vertical: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: "Pending · N items"
            //
            // Visual weight comes from labelSmall + letterSpacing +
            // fontWeight, not casing — `.toUpperCase()` would be a no-op
            // on '待處理'/'待处理' and break locale parity.
            Row(
              children: [
                Text(
                  l10n.homePendingSectionTitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(width: 8),
                PendingBadge(count: visible.length),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (final item in tilesToRender)
                  PendingTile(
                    key: ValueKey(item.id),
                    item: item,
                    category: item.categoryId != null
                        ? categories[item.categoryId]
                        : null,
                    account: accounts[item.accountId],
                    locale: locale,
                    onApprove: () => notifier.approve(item.id),
                    onSkip: () => notifier.skip(item.id),
                  ),
              ],
            ),
            if (showCollapseToggle)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? l10n.homePendingShowFewer
                        : l10n.homePendingShowMore(overflowCount),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Inline load-error banner. We use a plain Container instead of
/// MaterialBanner because MaterialBanner forces a non-empty `actions`
/// list (the ~48 px row appears even with `[SizedBox.shrink()]`).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: homePageCardHorizontalPadding,
        vertical: 12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single pending-row tile with Approve circle + swipe-left Skip.
class PendingTile extends StatelessWidget {
  const PendingTile({
    super.key,
    required this.item,
    required this.category,
    required this.account,
    required this.locale,
    required this.onApprove,
    required this.onSkip,
  });

  final PendingTransaction item;
  final Category? category;
  final Account? account;
  final String locale;

  /// Returns `true` on success and `false` on failure so the approve
  /// circle can reverse its 200 ms green animation when the underlying
  /// call fails.
  final Future<bool> Function() onApprove;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final categoryIcon = category != null
        ? iconForKey(category!.icon)
        : Icons.schedule;
    final categoryColor = category != null
        ? colorForIndex(category!.color)
        : theme.disabledColor;
    final categoryName = category != null
        ? categoryDisplayName(category!, l10n)
        : '';
    final accountName = account?.name ?? '';
    final dateStr = DateFormat.yMMMd(locale).format(item.date);
    final subtitleParts = <String>[
      if (categoryName.isNotEmpty) categoryName,
      if (accountName.isNotEmpty) accountName,
      dateStr,
    ];
    final subtitle = subtitleParts.join(' · ');

    final amountStr = MoneyFormatter.format(
      amountMinorUnits: item.amountMinorUnits,
      currency: item.currency,
      locale: locale,
    );

    return Slidable(
      key: ValueKey(item.id),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onSkip(),
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            label: l10n.homePendingSkip,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          border: Border(
            left: BorderSide(color: theme.colorScheme.tertiary, width: 3),
          ),
        ),
        child: ListTile(
          leading: Icon(categoryIcon, color: categoryColor, size: 24),
          title: Text(
            item.memo ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  amountStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _ApproveCircleButton(
                onApproveAsync: onApprove,
                semanticsLabel: l10n.homePendingApprove,
              ),
            ],
          ),
          onTap: null,
        ),
      ),
    );
  }
}

/// 36×36 circle Approve button with 200ms grey→green animation.
/// Debounces rapid taps via `_approving` flag. On failure the controller
/// returns `false` and the animation reverses (green → grey).
class _ApproveCircleButton extends StatefulWidget {
  const _ApproveCircleButton({
    required this.onApproveAsync,
    required this.semanticsLabel,
  });

  final Future<bool> Function() onApproveAsync;
  final String semanticsLabel;

  @override
  State<_ApproveCircleButton> createState() => _ApproveCircleButtonState();
}

class _ApproveCircleButtonState extends State<_ApproveCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Animation<Color?>? _colorAnimation;
  late final Animation<double> _scaleAnimation;
  bool _approving = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  /// Explicit green confirmation color — independent of `ColorScheme.tertiary`
  /// so the approve feedback reads as "success" regardless of theme.
  static const Color _kApproveGreen = Color(0xFF2E7D32); // Material green 800

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scheme = Theme.of(context).colorScheme;
    _colorAnimation = ColorTween(
      begin: scheme.surfaceContainerHighest,
      end: _kApproveGreen,
    ).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_approving) return;
    _approving = true;

    await _animController.forward();

    final success = await widget.onApproveAsync();

    if (!mounted) {
      _approving = false;
      return;
    }
    if (success) {
      _animController.reset();
    } else {
      await _animController.reverse();
    }
    _approving = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: GestureDetector(
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        _colorAnimation?.value ??
                        scheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: _animController.value > 0.5
                        ? Colors.white
                        : scheme.onSurface,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

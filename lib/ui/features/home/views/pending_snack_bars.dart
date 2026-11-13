// Shows PendingController's effects, and the Undo for its skip window, as
// snackbars. Mounted once above the shell in `router.dart`, so it is the
// controller's only effect listener and outlives any screen that lists
// pending rows.

import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../view_models/pending_controller.dart';
import '../view_models/pending_state.dart';

@Dependencies([PendingController])
class const PendingSnackBars({super.key, required final Widget child})
    extends ConsumerStatefulWidget {
  @override
  ConsumerState<PendingSnackBars> createState() => _PendingSnackBarsState();
}

class _PendingSnackBarsState extends ConsumerState<PendingSnackBars> {
  late final PendingController _controller;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undo;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(pendingControllerProvider.notifier)
      ..setEffectListener(_onEffect);
  }

  @override
  void dispose() {
    _controller.removeEffectListener(_onEffect);
    super.dispose();
  }

  void _onEffect(PendingEffect effect) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    final undoPending =
        _skippingId(ref.read(pendingControllerProvider)) != null;
    switch (effect) {
      case PendingApproveSucceededEffect(:final ruleName):
        if (undoPending) return;
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.homePendingApprovedSnack(ruleName))),
          );
      case PendingApproveFailedEffect():
      case PendingSkipFailedEffect():
        // Queued behind a live Undo rather than clearing it.
        if (!undoPending) messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.errorSnackbarGeneric)),
        );
    }
  }

  /// The Undo snackbar follows the controller's skip window: it opens when
  /// a row enters the window and closes when the window ends, since its own
  /// 4 s only start once it has entered. Both follow the state, so they run
  /// in the order the window changed even when one skip commits another.
  void _onSkipWindow(int? ended, int? started) {
    if (ended == started) return;
    if (ended != null) _undo?.close();
    if (started == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    final undo = _undo = messenger.showUndoSnackBar(
      message: l10n.homePendingSkippedSnack,
      undoLabel: l10n.commonUndo,
      onUndo: () => unawaited(_controller.undoSkip()),
    );
    // Once it is gone, close() would hide whichever snackbar is current.
    undo.closed.then((_) {
      if (_undo == undo) _undo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      pendingControllerProvider,
      (previous, next) =>
          _onSkipWindow(_skippingId(previous), _skippingId(next)),
    );
    return widget.child;
  }
}

int? _skippingId(AsyncValue<PendingState>? state) => switch (state?.value) {
  PendingData(:final skippingId) => skippingId,
  _ => null,
};

// Shows PendingController's effects as snackbars. Mounted once above the
// shell in `router.dart`, so it is the controller's only effect listener
// and outlives any screen that lists pending rows.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/widgets/undo_snack_bar.dart';
import '../view_models/pending_controller.dart';

@Dependencies([PendingController])
class PendingSnackBars extends ConsumerStatefulWidget {
  const PendingSnackBars({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PendingSnackBars> createState() => _PendingSnackBarsState();
}

class _PendingSnackBarsState extends ConsumerState<PendingSnackBars> {
  late final PendingController _controller;
  bool _skipUndoVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(pendingControllerProvider.notifier)
      ..setEffectListener(_onEffect);
  }

  @override
  void dispose() {
    _controller.setEffectListener(null);
    super.dispose();
  }

  void _onEffect(PendingEffect effect) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l10n = AppLocalizations.of(context);
    switch (effect) {
      case PendingSkipStartedEffect():
        _skipUndoVisible = true;
        messenger
            .showUndoSnackBar(
              message: l10n.homePendingSkippedSnack,
              undoLabel: l10n.commonUndo,
              onUndo: () => unawaited(_controller.undoSkip()),
            )
            .closed
            .then((_) {
              if (mounted) {
                _skipUndoVisible = false;
              }
            });
      case PendingApproveSucceededEffect(:final ruleName):
        if (_skipUndoVisible) {
          return;
        }
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.homePendingApprovedSnack(ruleName))),
          );
      case PendingApproveFailedEffect():
      case PendingSkipFailedEffect():
        _skipUndoVisible = false;
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.errorSnackbarGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

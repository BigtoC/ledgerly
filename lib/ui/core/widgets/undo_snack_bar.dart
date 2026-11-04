import 'package:flutter/material.dart';

import '../../../core/constants.dart';

extension UndoSnackBar on ScaffoldMessengerState {
  /// Shows [message] with an Undo action for [kUndoWindow]. Clears first so
  /// an older Undo snackbar cannot outlive the change it belongs to.
  ///
  /// `persist: false` is required: a SnackBar with an action otherwise
  /// ignores [SnackBar.duration] and stays after the change has committed.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showUndoSnackBar({
    required String message,
    required String undoLabel,
    required VoidCallback onUndo,
  }) {
    clearSnackBars();
    return showSnackBar(
      SnackBar(
        content: Text(message),
        duration: kUndoWindow,
        persist: false,
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
  }
}

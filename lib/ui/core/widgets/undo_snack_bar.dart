import 'package:flutter/material.dart';

import '../../../core/constants.dart';

extension UndoSnackBar on ScaffoldMessengerState {
  /// Shows [message] with an Undo action for [kUndoWindow]. Clears first so
  /// an older Undo snackbar cannot outlive the change it belongs to.
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
        action: SnackBarAction(label: undoLabel, onPressed: onUndo),
      ),
    );
  }
}

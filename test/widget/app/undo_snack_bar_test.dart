// `showUndoSnackBar` — the shared clear-then-show Undo snackbar.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/core/constants.dart';
import 'package:ledgerly/ui/core/widgets/undo_snack_bar.dart';

void main() {
  /// Pumps a button that shows the Undo snackbar and counts Undo taps.
  Future<List<void>> pumpShower(WidgetTester tester) async {
    final undos = <void>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showUndoSnackBar(
                message: 'Deleted',
                undoLabel: 'Undo',
                onUndo: () => undos.add(null),
              ),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    return undos;
  }

  testWidgets('Undo calls onUndo', (tester) async {
    final undos = await pumpShower(tester);
    expect(find.text('Deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undos, hasLength(1));
  });

  testWidgets('hides once the undo window has passed', (tester) async {
    await pumpShower(tester);
    await tester.pump(kUndoWindow);
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsNothing);
  });

  testWidgets('replaces an earlier snackbar instead of queueing', (
    tester,
  ) async {
    await pumpShower(tester);
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Deleted'), findsOneWidget);
  });
}

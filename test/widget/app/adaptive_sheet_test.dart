// `showAdaptiveSheet` — bottom sheet below 600dp, constrained dialog at
// 600dp and above.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/ui/core/widgets/adaptive_sheet.dart';

void main() {
  Future<void> open(WidgetTester tester, double width) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAdaptiveSheet<void>(
                context,
                heightFactor: 0.5,
                maxWidth: 300,
                maxHeight: 400,
                child: const SizedBox.expand(key: Key('body')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('390 wide opens a bottom sheet at heightFactor', (tester) async {
    await open(tester, 390);
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    final sheet = tester.widget<FractionallySizedBox>(
      find.ancestor(
        of: find.byKey(const Key('body')),
        matching: find.byType(FractionallySizedBox),
      ),
    );
    expect(sheet.heightFactor, 0.5);
  });

  testWidgets('1000 wide opens a dialog with the max constraints', (
    tester,
  ) async {
    await open(tester, 1000);
    expect(find.byType(BottomSheet), findsNothing);
    final dialog = tester.widget<Dialog>(find.byType(Dialog));
    expect(dialog.clipBehavior, Clip.antiAlias);
    final box = tester.widget<ConstrainedBox>(
      find
          .ancestor(
            of: find.byKey(const Key('body')),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(
      box.constraints,
      const BoxConstraints(maxWidth: 300, maxHeight: 400),
    );
  });
}

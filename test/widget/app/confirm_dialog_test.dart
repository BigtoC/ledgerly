// `showConfirmDialog` — the shared Cancel / confirm AlertDialog.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/widgets/confirm_dialog.dart';

void main() {
  /// Pumps a button that opens the dialog and stores its result.
  Future<List<bool>> pumpOpener(
    WidgetTester tester, {
    String? title,
    bool tonal = false,
  }) async {
    final results = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(
              await showConfirmDialog(
                context,
                title: title,
                body: 'Body',
                confirmLabel: 'Go',
                tonal: tonal,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('confirm returns true', (tester) async {
    final results = await pumpOpener(tester, title: 'Title');
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Go'), findsOneWidget);
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });

  testWidgets('Cancel returns false', (tester) async {
    final results = await pumpOpener(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('barrier dismiss returns false', (tester) async {
    final results = await pumpOpener(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('omits the title when null', (tester) async {
    await pumpOpener(tester);
    final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
    expect(dialog.title, isNull);
  });

  Color? confirmBackground(WidgetTester tester) {
    final finder = find.widgetWithText(FilledButton, 'Go');
    final button = tester.widget<FilledButton>(finder);
    return button
        .defaultStyleOf(tester.element(finder))
        .backgroundColor
        ?.resolve({});
  }

  testWidgets('tonal picks the tonal confirm style', (tester) async {
    await pumpOpener(tester, tonal: true);
    final theme = Theme.of(tester.element(find.byType(AlertDialog)));
    expect(confirmBackground(tester), theme.colorScheme.secondaryContainer);
  });

  testWidgets('default picks the filled confirm style', (tester) async {
    await pumpOpener(tester);
    final theme = Theme.of(tester.element(find.byType(AlertDialog)));
    expect(confirmBackground(tester), theme.colorScheme.primary);
  });
}

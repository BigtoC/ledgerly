import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ledgerly/features/analysis/analysis_screen.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Widget _wrap({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('AN01: AnalysisScreen renders placeholder title and body', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Analysis is coming in Phase 2'), findsOneWidget);
    expect(
      find.text('Charts and summaries will appear here once Phase 2 lands.'),
      findsOneWidget,
    );
  });

  testWidgets('AN02: AnalysisScreen AppBar title says Analysis', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Analysis'), findsOneWidget); // AppBar title only
  });

  testWidgets('AN03: AnalysisScreen has no FAB', (tester) async {
    await tester.pumpWidget(_wrap(child: const AnalysisScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
  });
}

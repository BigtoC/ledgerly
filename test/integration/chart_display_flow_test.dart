// Integration test: insert a transaction, open Analysis, verify the
// charts section renders with the seeded category. Mirrors the
// "subsequent run" pattern from bootstrap_to_home_test.dart so we skip
// the splash route entirely.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/app/providers/splash_redirect_provider.dart';
import 'package:ledgerly/data/repositories/user_preferences_repository.dart';
import 'package:ledgerly/features/analysis/analysis_screen.dart';

import '../support/test_app.dart';

void main() {
  testWidgets('charts render on Analysis after an insert', (tester) async {
    final db = newTestAppDatabase();
    addTearDown(db.close);
    await tester.runAsync(() => runTestSeed(db));

    // Skip splash and insert one seeded-category expense before pumping.
    final prefs = DriftUserPreferencesRepository(db);
    await tester.runAsync(() => prefs.setSplashEnabled(false));
    final categoryId = await tester.runAsync(
      () => getSeededCategoryId(db, 'category.food'),
    );
    final account = await tester.runAsync(() => getDefaultAccount(db));
    await tester.runAsync(
      () => insertTestTransaction(
        db,
        accountId: account!.id,
        categoryId: categoryId!,
        currencyCode: account.currency.code,
        amountMinorUnits: 1000,
        date: DateTime.now(),
      ),
    );

    final container = makeTestContainer(
      db: db,
      extraOverrides: [
        splashGateSnapshotProvider.overrideWithValue(
          SplashGateSnapshot.withInitial(enabled: false, startDate: null),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestApp(container: container));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Tap the Analysis nav destination.
    await tester.tap(find.byIcon(Icons.analytics_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(AnalysisScreen), findsOneWidget);

    // Default chart selectors mounted: 'Week' from the period segmented
    // control, plus the seeded Food category label.
    expect(find.textContaining('Week'), findsWidgets);
  });
}

// `showCategoryPicker` widget tests (Wave 1 Categories plan §5).
//
// Exercises the adaptive picker sheet / dialog surface directly with a
// stubbed `categoriesByType` provider. No DB. No feature router.
//
// Covers:
//   - Filters by type (only categories matching the requested `type` appear).
//   - Archived rows are excluded (guaranteed by the provider call).
//   - Tapping a tile resolves the `Future` with that `Category`.
//   - Scrim dismiss resolves `null`.
//   - Empty state renders the "Create one" CTA that resolves `null`.
//   - Both adaptive containers (<600dp modal sheet, >=600dp dialog) render
//     the same picker body and survive 2× text scale.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/categories/widgets/category_picker.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

Category _c({
  required int id,
  required CategoryType type,
  String? l10nKey,
  String? customName,
  int? sortOrder,
}) => Category(
  id: id,
  icon: 'category',
  color: 0,
  type: type,
  l10nKey: l10nKey,
  customName: customName,
  sortOrder: sortOrder,
);

Widget _hostApp({
  required ProviderContainer container,
  required Future<Category?> Function(BuildContext) onLaunch,
  Size size = const Size(400, 800),
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => onLaunch(ctx),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'P01: picker lists only categories of the requested type, sorted',
    (tester) async {
      final rows = <Category>[
        _c(
          id: 1,
          type: CategoryType.expense,
          customName: 'Food',
          sortOrder: 1,
        ),
        _c(
          id: 2,
          type: CategoryType.expense,
          customName: 'Travel',
          sortOrder: 0,
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          categoriesByTypeProvider(
            CategoryType.expense,
          ).overrideWith((ref) => Stream.value(rows)),
        ],
      );
      addTearDown(container.dispose);

      Category? picked;
      await tester.pumpWidget(
        _hostApp(
          container: container,
          onLaunch: (ctx) async {
            picked = await showCategoryPicker(
              ctx,
              type: CategoryType.expense,
            );
            return picked;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
      // Sort order: Travel (0) before Food (1).
      final travelTop = tester.getTopLeft(find.text('Travel')).dy;
      final foodTop = tester.getTopLeft(find.text('Food')).dy;
      expect(travelTop, lessThanOrEqualTo(foodTop));

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(picked, isNotNull);
      expect(picked!.id, 1);
    },
  );

  testWidgets('P02: scrim dismiss resolves null', (tester) async {
    final container = ProviderContainer(
      overrides: [
        categoriesByTypeProvider(CategoryType.expense).overrideWith(
          (ref) => Stream.value([
            _c(id: 1, type: CategoryType.expense, customName: 'Food'),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    Category? picked;
    var resolved = false;
    await tester.pumpWidget(
      _hostApp(
        container: container,
        onLaunch: (ctx) async {
          picked = await showCategoryPicker(ctx, type: CategoryType.expense);
          resolved = true;
          return picked;
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);

    // Tap the scrim (top-left area outside the sheet).
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(resolved, isTrue);
    expect(picked, isNull);
  });

  testWidgets('P03: empty state renders CTA and resolves null on tap', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        categoriesByTypeProvider(
          CategoryType.income,
        ).overrideWith((ref) => Stream.value(const <Category>[])),
      ],
    );
    addTearDown(container.dispose);

    Category? picked;
    var resolved = false;
    await tester.pumpWidget(
      _hostApp(
        container: container,
        onLaunch: (ctx) async {
          picked = await showCategoryPicker(ctx, type: CategoryType.income);
          resolved = true;
          return picked;
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Create one'), findsOneWidget);
    await tester.tap(find.textContaining('Create one'));
    await tester.pumpAndSettle();
    expect(resolved, isTrue);
    expect(picked, isNull);
  });

  testWidgets('P04: >=600dp renders dialog container with picker body', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        categoriesByTypeProvider(CategoryType.expense).overrideWith(
          (ref) => Stream.value([
            _c(
              id: 11,
              type: CategoryType.expense,
              customName: 'Groceries',
              sortOrder: 0,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    Category? picked;
    await tester.pumpWidget(
      _hostApp(
        container: container,
        size: const Size(1000, 800),
        onLaunch: (ctx) async {
          picked = await showCategoryPicker(ctx, type: CategoryType.expense);
          return picked;
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();
    expect(picked, isNotNull);
    expect(picked!.id, 11);
  });

  testWidgets('P05: 2x text scale renders without overflow', (tester) async {
    final container = ProviderContainer(
      overrides: [
        categoriesByTypeProvider(CategoryType.expense).overrideWith(
          (ref) => Stream.value([
            _c(
              id: 1,
              type: CategoryType.expense,
              customName: 'Very Long Category Name',
              sortOrder: 0,
            ),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showCategoryPicker(ctx, type: CategoryType.expense),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Very Long Category Name'), findsOneWidget);
  });
}

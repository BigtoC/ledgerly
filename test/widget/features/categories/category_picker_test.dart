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
//   - The <600dp sheet takes 90% of the screen height.
//   - The grid shows five tiles per row, and a long label shrinks to fit
//     its tile on one line instead of wrapping.
//   - Omitting `type` lists expense categories, then income categories
//     below them.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/categories/widgets/category_picker.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

Category _c({
  required int id,
  required CategoryType type,
  String? customName,
  int? sortOrder,
}) => Category(
  id: id,
  icon: 'category',
  color: 0,
  type: type,
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

@Dependencies([categoriesByType])
void main() {
  setUpAll(() {
    registerFallbackValue(
      const Category(
        id: 0,
        icon: 'category',
        color: 0,
        type: CategoryType.expense,
      ),
    );
  });

  testWidgets(
    'P01: picker lists only categories of the requested type, sorted',
    (tester) async {
      final rows = <Category>[
        _c(id: 1, type: CategoryType.expense, customName: 'Food', sortOrder: 1),
        _c(
          id: 2,
          type: CategoryType.expense,
          customName: 'Travel',
          sortOrder: 0,
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(rows)),
        ],
      );
      addTearDown(container.dispose);

      Category? picked;
      await tester.pumpWidget(
        _hostApp(
          container: container,
          onLaunch: (ctx) async {
            picked = await showCategoryPicker(ctx, type: CategoryType.expense);
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
        categoriesByTypeProvider(CategoryType.income)
            .overrideWith((ref) => Stream.value(const <Category>[])),
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
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
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

  testWidgets(
    'P06: real categoriesByType provider requests includeArchived=false for the selected type',
    (tester) async {
      final repo = _MockCategoryRepository();
      when(
        () => repo.watchAll(type: CategoryType.expense, includeArchived: false),
      ).thenAnswer(
        (_) => Stream.value([
          _c(id: 1, type: CategoryType.expense, customName: 'Food'),
        ]),
      );

      final container = ProviderContainer(
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      Category? picked;
      await tester.pumpWidget(
        _hostApp(
          container: container,
          onLaunch: (ctx) async {
            picked = await showCategoryPicker(ctx, type: CategoryType.expense);
            return picked;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Food'), findsOneWidget);
      verify(
        () => repo.watchAll(type: CategoryType.expense, includeArchived: false),
      ).called(1);
    },
  );

  group('phone layout', () {
    @Dependencies([categoriesByType])
    Future<void> openPicker(
      WidgetTester tester, {
      required List<Category> expense,
      List<Category> income = const [],
      CategoryType? type = CategoryType.expense,
      void Function(Category?)? onPicked,
    }) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer(
        overrides: [
          categoriesByTypeProvider(CategoryType.expense)
              .overrideWith((ref) => Stream.value(expense)),
          categoriesByTypeProvider(CategoryType.income)
              .overrideWith((ref) => Stream.value(income)),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        _hostApp(
          container: container,
          onLaunch: (ctx) async {
            final picked = await showCategoryPicker(ctx, type: type);
            onPicked?.call(picked);
            return picked;
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('P07: the sheet takes 90% of the screen height', (
      tester,
    ) async {
      await openPicker(
        tester,
        expense: [_c(id: 1, type: CategoryType.expense, customName: 'Food')],
      );

      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        closeTo(800 * 0.9, 1),
      );
    });

    testWidgets('P08: the grid shows five tiles per row', (tester) async {
      await openPicker(
        tester,
        expense: [
          for (var i = 1; i <= 7; i++)
            _c(
              id: i,
              type: CategoryType.expense,
              customName: 'C$i',
              sortOrder: i,
            ),
        ],
      );

      final firstRowTop = tester.getTopLeft(find.text('C1')).dy;
      for (var i = 2; i <= 5; i++) {
        expect(tester.getTopLeft(find.text('C$i')).dy, firstRowTop);
      }
      expect(tester.getTopLeft(find.text('C6')).dy, greaterThan(firstRowTop));
      expect(
        tester.getTopLeft(find.text('C6')).dx,
        tester.getTopLeft(find.text('C1')).dx,
      );
    });

    testWidgets('P09: a long label shrinks onto one line inside its tile', (
      tester,
    ) async {
      await openPicker(
        tester,
        expense: [
          _c(
            id: 1,
            type: CategoryType.expense,
            customName: 'Transportation',
            sortOrder: 0,
          ),
          _c(
            id: 2,
            type: CategoryType.expense,
            customName: 'Food',
            sortOrder: 1,
          ),
        ],
      );

      final longLabel = tester.getRect(find.text('Transportation'));
      final shortLabel = tester.getRect(find.text('Food'));
      final tile = tester.getRect(
        find.ancestor(
          of: find.text('Transportation'),
          matching: find.byType(InkWell),
        ),
      );
      // One line: no taller than a label that certainly fits.
      expect(longLabel.height, lessThanOrEqualTo(shortLabel.height));
      expect(longLabel.left, greaterThanOrEqualTo(tile.left));
      expect(longLabel.right, lessThanOrEqualTo(tile.right));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'P10: without a type, income categories follow the expense ones',
      (tester) async {
        Category? picked;
        await openPicker(
          tester,
          type: null,
          expense: [_c(id: 1, type: CategoryType.expense, customName: 'Food')],
          income: [_c(id: 2, type: CategoryType.income, customName: 'Salary')],
          onPicked: (c) => picked = c,
        );

        expect(find.text('Pick expense category'), findsOneWidget);
        expect(find.text('Pick income category'), findsOneWidget);
        final foodTop = tester.getTopLeft(find.text('Food')).dy;
        final incomeTitleTop = tester
            .getTopLeft(find.text('Pick income category'))
            .dy;
        final salaryTop = tester.getTopLeft(find.text('Salary')).dy;
        expect(incomeTitleTop, greaterThan(foodTop));
        expect(salaryTop, greaterThan(incomeTitleTop));

        await tester.tap(find.text('Salary'));
        await tester.pumpAndSettle();
        expect(picked?.id, 2);
        expect(picked?.type, CategoryType.income);
      },
    );

    testWidgets('P11: without a type, an empty type drops its section', (
      tester,
    ) async {
      await openPicker(
        tester,
        type: null,
        expense: const [],
        income: [_c(id: 2, type: CategoryType.income, customName: 'Salary')],
      );

      expect(find.text('Pick expense category'), findsNothing);
      expect(find.text('Pick income category'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.textContaining('Create one'), findsNothing);
    });
  });
}

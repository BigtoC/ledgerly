// Categories management screen widget tests (plan §3.3, §4).
//
// Exercises the screen directly with a fake `CategoriesController` and
// mock `CategoryRepository`. No live DB; no full-app router.
//
// Covers:
//   - Sections render in order: Expense then Income.
//   - Per-section empty CTA renders when a type has no visible rows.
//   - FAB opens the form sheet.
//   - Archive action surfaces the undo snackbar.
//   - Edit-mode disables the Type toggle (plan §12 risk #2).
//   - 2× text scale survives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/category.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/categories/categories_screen.dart';
import 'package:ledgerly/features/categories/categories_state.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

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

CategoryRowView _row(
  Category c, [
  CategoryRowAffordance affordance = CategoryRowAffordance.archive,
]) => CategoryRowView(category: c, affordance: affordance);

class _FakeCategoriesController extends CategoriesController {
  _FakeCategoriesController(this._fixed);
  final CategoriesState _fixed;

  @override
  Stream<CategoriesState> build() async* {
    yield _fixed;
  }
}

Widget _wrap({
  required ProviderContainer container,
  double textScale = 1.0,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const CategoriesScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Category(id: 0, icon: 'category', color: 0, type: CategoryType.expense),
    );
  });

  testWidgets(
    'S01: data state renders both section headers in order',
    (tester) async {
      final repo = _MockCategoryRepository();
      final container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repo),
          categoriesControllerProvider.overrideWith(
            () => _FakeCategoriesController(
              CategoriesState.data(
                expense: [
                  _row(
                    _c(
                      id: 1,
                      type: CategoryType.expense,
                      customName: 'Food',
                    ),
                  ),
                ],
                income: [
                  _row(
                    _c(
                      id: 2,
                      type: CategoryType.income,
                      customName: 'Salary',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);

      final expenseTop = tester.getTopLeft(find.text('Expense')).dy;
      final incomeTop = tester.getTopLeft(find.text('Income')).dy;
      expect(expenseTop, lessThan(incomeTop));
    },
  );

  testWidgets('S02: empty section renders inline Add CTA', (tester) async {
    final repo = _MockCategoryRepository();
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [
                _row(
                  _c(
                    id: 1,
                    type: CategoryType.expense,
                    customName: 'Food',
                  ),
                ),
              ],
              income: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    // The income section is empty; the add-CTA must be findable there.
    expect(find.text('Add category'), findsWidgets);
  });

  testWidgets('S03: FAB opens the add form sheet', (tester) async {
    final repo = _MockCategoryRepository();
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            const CategoriesState.data(expense: [], income: []),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Form sheet fields are present.
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
  });

  testWidgets(
    'S04: tapping a tile opens form sheet in Edit mode with type disabled',
    (tester) async {
      final repo = _MockCategoryRepository();
      final container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repo),
          categoriesControllerProvider.overrideWith(
            () => _FakeCategoriesController(
              CategoriesState.data(
                expense: [
                  _row(
                    _c(
                      id: 1,
                      type: CategoryType.expense,
                      customName: 'Food',
                    ),
                  ),
                ],
                income: const [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Locked-hint visible in Edit mode.
      expect(find.text('Type cannot change after first use'), findsOneWidget);
      final segmented = tester.widget<SegmentedButton<CategoryType>>(
        find.byType(SegmentedButton<CategoryType>),
      );
      expect(segmented.onSelectionChanged, isNull);
    },
  );

  testWidgets('S05: 2x text scale renders without overflow', (tester) async {
    final repo = _MockCategoryRepository();
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [
                _row(
                  _c(
                    id: 1,
                    type: CategoryType.expense,
                    customName: 'A really quite long custom category name',
                  ),
                ),
              ],
              income: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container, textScale: 2.0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('S06: archive action emits an undo snackbar', (tester) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 9, type: CategoryType.expense, customName: 'Hobby');
    when(() => repo.archive(9)).thenAnswer(
      (_) async => cat.copyWith(isArchived: true),
    );
    when(() => repo.getById(9)).thenAnswer((_) async => cat);
    when(
      () => repo.save(any()),
    ).thenAnswer((inv) async => inv.positionalArguments.first as Category);

    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [_row(cat, CategoryRowAffordance.archive)],
              income: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    // Trigger the row archive via its exposed action — the widget should
    // expose the archive action on a per-row widget. We drive the public
    // affordance by looking up the row's on-tap archive gesture. We use
    // a dedicated Key on the tile's archive button.
    await tester.tap(find.byKey(const ValueKey('categoryTile:9:archive')));
    await tester.pumpAndSettle();

    expect(find.text('Category archived'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    verify(() => repo.archive(9)).called(1);
  });
}

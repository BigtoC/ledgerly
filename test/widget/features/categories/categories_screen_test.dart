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
//   - Blocked delete / archive / save show localized messages, never the
//     repository's English developer strings.
//   - Edit-mode disables the Type toggle (plan §12 risk #2).
//   - 2× text scale survives.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

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
  String? customName,
}) => Category(
  id: id,
  icon: 'category',
  color: 0,
  type: type,
  customName: customName,
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

@Dependencies([CategoriesController])
Widget _wrap({
  required ProviderContainer container,
  double textScale = 1.0,
  Locale? locale,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const CategoriesScreen(),
    ),
  );
}

@Dependencies([CategoriesController])
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

  testWidgets('S01: data state renders both section headers in order', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [
                _row(_c(id: 1, type: CategoryType.expense, customName: 'Food')),
              ],
              income: [
                _row(
                  _c(id: 2, type: CategoryType.income, customName: 'Salary'),
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
  });

  testWidgets('S02: empty section renders inline Add CTA', (tester) async {
    final repo = _MockCategoryRepository();
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [
                _row(_c(id: 1, type: CategoryType.expense, customName: 'Food')),
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
                    _c(id: 1, type: CategoryType.expense, customName: 'Food'),
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
    when(() => repo.archive(9))
        .thenAnswer((_) async => cat.copyWith(isArchived: true));
    when(() => repo.getById(9)).thenAnswer((_) async => cat);
    when(() => repo.save(any()))
        .thenAnswer((inv) async => inv.positionalArguments.first as Category);

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

  ProviderContainer singleRowContainer(
    _MockCategoryRepository repo,
    Category cat,
    CategoryRowAffordance affordance,
  ) {
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [_row(cat, affordance)],
              income: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> deleteAndConfirm(WidgetTester tester, int id) async {
    await tester.tap(find.byKey(ValueKey('categoryTile:$id:delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
  }

  testWidgets('S07: blocked delete shows the localized in-use message', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 12, type: CategoryType.expense, customName: 'Hobby');
    when(() => repo.delete(12)).thenThrow(const CategoryInUseException(12));
    final container = singleRowContainer(
      repo,
      cat,
      CategoryRowAffordance.delete,
    );

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();
    await deleteAndConfirm(tester, 12);

    expect(
      find.text("This category is still in use, so it can't be deleted."),
      findsOneWidget,
    );
    expect(find.textContaining('Category 12'), findsNothing);
  });

  testWidgets('S08: blocked delete message follows the zh_TW locale', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 12, type: CategoryType.expense, customName: 'Hobby');
    when(() => repo.delete(12)).thenThrow(const CategoryInUseException(12));
    final container = singleRowContainer(
      repo,
      cat,
      CategoryRowAffordance.delete,
    );

    await tester.pumpWidget(
      _wrap(container: container, locale: const Locale('zh', 'TW')),
    );
    await tester.pumpAndSettle();
    await deleteAndConfirm(tester, 12);

    expect(find.text('此分類仍在使用中，無法刪除。'), findsOneWidget);
  });

  testWidgets(
    'S09: archive blocked by a recurring rule shows the localized message',
    (tester) async {
      final repo = _MockCategoryRepository();
      final cat = _c(id: 9, type: CategoryType.expense, customName: 'Rent');
      when(() => repo.archive(9))
          .thenThrow(const CategoryHasRecurringRuleException(9));
      final container = singleRowContainer(
        repo,
        cat,
        CategoryRowAffordance.archive,
      );

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('categoryTile:9:archive')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'An active recurring transaction uses this category, '
          "so it can't be archived.",
        ),
        findsOneWidget,
      );
      expect(find.text('Category archived'), findsNothing);
    },
  );

  testWidgets('S10: other archive failures keep the generic snackbar', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 9, type: CategoryType.expense, customName: 'Rent');
    when(() => repo.archive(9))
        .thenThrow(const CategoryRepositoryException('Category 9 not found'));
    final container = singleRowContainer(
      repo,
      cat,
      CategoryRowAffordance.archive,
    );

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('categoryTile:9:archive')));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'S11: type-locked save shows the localized inline error and keeps the '
    'sheet open',
    (tester) async {
      final repo = _MockCategoryRepository();
      final cat = _c(id: 3, type: CategoryType.expense, customName: 'Food');
      // Synthetic: the real rename() never type-locks (Edit keeps the
      // stored type). This only exercises the typeLocked -> message map.
      when(() => repo.rename(3, 'Groceries'))
          .thenThrow(const CategoryTypeLockedException(3));
      final container = singleRowContainer(
        repo,
        cat,
        CategoryRowAffordance.archive,
      );

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Groceries');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "This category's type can't change after it has been used. "
          'Create a new category instead.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('id: 3'), findsNothing);
      // Sheet stays open and Save is enabled again for a retry.
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save.onPressed, isNotNull);
    },
  );
}

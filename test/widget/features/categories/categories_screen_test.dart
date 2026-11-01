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
//   - Blocked delete / archive show localized messages; other failed
//     saves, deletes, archives, undos and reorders show the generic one,
//     never the repository's English developer strings, even while an
//     Undo snackbar is still up.
//   - Undo still restores the category after the screen is gone, and a
//     save that fails after its sheet closed raises no error.
//   - A failed rename skips the icon/color write.
//   - Edit-mode disables the Type toggle (plan §12 risk #2).
//   - Edit Save with a blank name: allowed for seeded rows (issue #83),
//     blocked for custom rows.
//   - 2× text scale survives.

import 'dart:async';

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

/// Starts on a plain page that pushes [CategoriesScreen], so a test can
/// leave the screen with the back button.
@Dependencies([CategoriesController])
Widget _wrapBehindLauncher({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CategoriesScreen(),
                ),
              ),
              child: const Text('Open categories'),
            ),
          ),
        ),
      ),
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

  testWidgets('S11: a failed save shows the generic inline error and keeps the '
      'sheet open', (tester) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 3, type: CategoryType.expense, customName: 'Food');
    when(() => repo.rename(3, 'Groceries'))
        .thenThrow(const CategoryRepositoryException('Category 3 not found'));
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
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Category 3'), findsNothing);
    // Sheet stays open and Save is enabled again for a retry.
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(save.onPressed, isNotNull);
  });

  testWidgets(
    'S12: a save that fails after the sheet is closed raises no error',
    (tester) async {
      final repo = _MockCategoryRepository();
      final cat = _c(id: 3, type: CategoryType.expense, customName: 'Food');
      final rename = Completer<Category>();
      when(() => repo.rename(3, 'Groceries')).thenAnswer((_) => rename.future);
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
      await tester.pump();

      // Barrier tap closes the sheet while the rename is still running.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      rename.completeError(
        const CategoryRepositoryException('Category 3 not found'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'S13: Undo tapped after leaving the screen restores the category',
    (tester) async {
      final repo = _MockCategoryRepository();
      final cat = _c(id: 9, type: CategoryType.expense, customName: 'Hobby');
      final archived = cat.copyWith(isArchived: true);
      when(() => repo.archive(9)).thenAnswer((_) async => archived);
      when(() => repo.getById(9)).thenAnswer((_) async => archived);
      when(() => repo.save(any()))
          .thenAnswer((inv) async => inv.positionalArguments.first as Category);
      final container = singleRowContainer(
        repo,
        cat,
        CategoryRowAffordance.archive,
      );

      await tester.pumpWidget(_wrapBehindLauncher(container: container));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('categoryTile:9:archive')));
      await tester.pumpAndSettle();
      expect(find.text('Category archived'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CategoriesScreen), findsNothing);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final saved =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(saved.id, 9);
      expect(saved.isArchived, isFalse);
      expect(find.text('Category archived'), findsNothing);
    },
  );

  testWidgets('S14: a failed Undo shows the generic snackbar', (tester) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 9, type: CategoryType.expense, customName: 'Hobby');
    final archived = cat.copyWith(isArchived: true);
    when(() => repo.archive(9)).thenAnswer((_) async => archived);
    when(() => repo.getById(9)).thenAnswer((_) async => archived);
    when(() => repo.save(any()))
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
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets('S15: other delete failures show the generic snackbar', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 12, type: CategoryType.expense, customName: 'Hobby');
    when(() => repo.delete(12))
        .thenThrow(const CategoryRepositoryException('Category 12 failed'));
    final container = singleRowContainer(
      repo,
      cat,
      CategoryRowAffordance.delete,
    );

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();
    await deleteAndConfirm(tester, 12);

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('Category 12'), findsNothing);
  });

  testWidgets('S16: a failed reorder shows the generic snackbar', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final alpha = _c(id: 1, type: CategoryType.expense, customName: 'Alpha');
    final beta = _c(id: 2, type: CategoryType.expense, customName: 'Beta');
    when(() => repo.reorder([2, 1])).thenThrow(Exception('injected'));
    final container = ProviderContainer(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
        categoriesControllerProvider.overrideWith(
          () => _FakeCategoriesController(
            CategoriesState.data(
              expense: [_row(alpha), _row(beta)],
              income: const [],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_wrap(container: container));
    await tester.pumpAndSettle();

    // Move Beta above Alpha through the list's drop callback. A real drag
    // builds the drag proxy, which has no Material ancestor here.
    tester
        .widget<SliverReorderableList>(find.byType(SliverReorderableList))
        .onReorderItem!(1, 0);
    await tester.pumpAndSettle();

    verify(() => repo.reorder([2, 1])).called(1);
    expect(tester.takeException(), isNull);
    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'S16b: a failed reorder shows its message while an Undo snackbar is up',
    (tester) async {
      final repo = _MockCategoryRepository();
      final alpha = _c(id: 1, type: CategoryType.expense, customName: 'Alpha');
      final beta = _c(id: 2, type: CategoryType.expense, customName: 'Beta');
      when(() => repo.archive(1))
          .thenAnswer((_) async => alpha.copyWith(isArchived: true));
      when(() => repo.reorder([2, 1])).thenThrow(Exception('injected'));
      final container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repo),
          categoriesControllerProvider.overrideWith(
            () => _FakeCategoriesController(
              CategoriesState.data(
                expense: [_row(alpha), _row(beta)],
                income: const [],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('categoryTile:1:archive')));
      await tester.pumpAndSettle();
      // A SnackBar with an action stays until dismissed.
      expect(find.text('Category archived'), findsOneWidget);

      tester
          .widget<SliverReorderableList>(find.byType(SliverReorderableList))
          .onReorderItem!(1, 0);
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('S17: a failed rename skips the icon and color update', (
    tester,
  ) async {
    final repo = _MockCategoryRepository();
    final cat = _c(id: 3, type: CategoryType.expense, customName: 'Food');
    when(() => repo.rename(3, 'Groceries'))
        .thenThrow(const CategoryRepositoryException('Category 3 not found'));
    when(() => repo.getById(3)).thenAnswer((_) async => cat);
    when(() => repo.save(any()))
        .thenAnswer((inv) async => inv.positionalArguments.first as Category);
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
    // The form's color swatch is the only bordered circle in the sheet.
    await tester.tap(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration! as BoxDecoration).border != null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(of: find.byType(GridView), matching: find.byType(InkWell))
          .at(3),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    verifyNever(() => repo.save(any()));
  });

  // Issue #83: a seeded row has no customName, so its Name field opens
  // empty. A blank name on a seeded row means "use the localized name",
  // so it must not block Save.
  group('edit Save with a blank name', () {
    const seededFood = Category(
      id: 1,
      icon: 'category',
      color: 0,
      type: CategoryType.expense,
      l10nKey: 'category.food',
    );

    FilledButton saveButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

    Future<void> openEditSheet(WidgetTester tester, String tileLabel) async {
      await tester.tap(find.text(tileLabel));
      await tester.pumpAndSettle();
    }

    testWidgets('seeded row saves a color-only change', (tester) async {
      final repo = _MockCategoryRepository();
      when(() => repo.getById(1)).thenAnswer((_) async => seededFood);
      when(() => repo.save(any()))
          .thenAnswer((inv) async => inv.positionalArguments.first as Category);
      final container = singleRowContainer(
        repo,
        seededFood,
        CategoryRowAffordance.archive,
      );

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      await openEditSheet(tester, 'Food');

      // The form's color swatch is the only bordered circle in the sheet.
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
                (w.decoration! as BoxDecoration).border != null,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .at(3),
      );
      await tester.pumpAndSettle();

      expect(saveButton(tester).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      final saved =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(saved.id, 1);
      expect(saved.color, 3);
      expect(saved.l10nKey, 'category.food');
      expect(saved.customName, isNull);
      verifyNever(() => repo.rename(any(), any()));
      // Sheet closed after a successful save.
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('clearing a seeded row\'s custom name reverts it on Save', (
      tester,
    ) async {
      final repo = _MockCategoryRepository();
      final renamed = seededFood.copyWith(customName: 'Groceries');
      when(() => repo.rename(1, any())).thenAnswer((_) async => seededFood);
      final container = singleRowContainer(
        repo,
        renamed,
        CategoryRowAffordance.archive,
      );

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      await openEditSheet(tester, 'Groceries');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(saveButton(tester).onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // The repository maps a blank name to null: the localized default.
      final name = verify(() => repo.rename(1, captureAny())).captured.single;
      expect(name, anyOf(isNull, isEmpty));
      verifyNever(() => repo.save(any()));
    });

    testWidgets('custom row keeps Save disabled with a blank name', (
      tester,
    ) async {
      final repo = _MockCategoryRepository();
      final cat = _c(id: 5, type: CategoryType.expense, customName: 'Hobby');
      final container = singleRowContainer(
        repo,
        cat,
        CategoryRowAffordance.delete,
      );

      await tester.pumpWidget(_wrap(container: container));
      await tester.pumpAndSettle();
      await openEditSheet(tester, 'Hobby');
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      expect(saveButton(tester).onPressed, isNull);
    });
  });
}

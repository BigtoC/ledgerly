// CategoriesController unit tests (plan §3.3, §7).
//
// Covers:
//   - loading → data stream transitions.
//   - Per-row `CategoryRowAffordance` computation (archive for seeded,
//     archive for referenced custom, delete for unused custom).
//   - Seeded + unreferenced → Archive, not Delete (plan §12 risk #3).
//   - Archived rows are excluded from the state.
//   - Commands route to the repository and return an outcome per
//     command, never throwing: typed repository exceptions map to their
//     variants and every other failure to `failed`.
//
// Repository is mocked via `mocktail`; no live DB.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/data/repositories/category_repository.dart';
import 'package:ledgerly/features/categories/categories_controller.dart';
import 'package:ledgerly/features/categories/categories_state.dart';

class _MockCategoryRepository extends Mock implements CategoryRepository {}

Category _c({
  required int id,
  required CategoryType type,
  String? l10nKey,
  String? customName,
  int? sortOrder,
  bool isArchived = false,
}) => Category(
  id: id,
  icon: 'category',
  color: 0,
  type: type,
  l10nKey: l10nKey,
  customName: customName,
  sortOrder: sortOrder,
  isArchived: isArchived,
);

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

  group('CategoriesController', () {
    late _MockCategoryRepository repo;
    late StreamController<List<Category>> rowsCtrl;

    setUp(() {
      repo = _MockCategoryRepository();
      rowsCtrl = StreamController<List<Category>>.broadcast();
      when(() => repo.watchAll(includeArchived: false))
          .thenAnswer((_) => rowsCtrl.stream);
      when(() => repo.isReferenced(any())).thenAnswer((_) async => false);
    });

    tearDown(() async {
      await rowsCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [categoryRepositoryProvider.overrideWithValue(repo)],
      );
    }

    @Dependencies([CategoriesController])
    Future<CategoriesState> waitForData(ProviderContainer c) async {
      for (var i = 0; i < 100; i++) {
        final s = c.read(categoriesControllerProvider);
        if (s is AsyncData<CategoriesState> && s.value is CategoriesData) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('CategoriesController never produced data');
    }

    test(
      'C01: starts in loading and transitions to data on first emit',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});

        expect(
          container.read(categoriesControllerProvider),
          isA<AsyncLoading<CategoriesState>>(),
        );

        await Future<void>.delayed(Duration.zero);
        rowsCtrl.add([
          _c(id: 1, type: CategoryType.expense, customName: 'Food'),
          _c(id: 2, type: CategoryType.income, customName: 'Salary'),
        ]);

        final state = await waitForData(container) as CategoriesData;
        expect(state.expense, hasLength(1));
        expect(state.income, hasLength(1));
        expect(state.expense.single.category.customName, 'Food');
        expect(state.income.single.category.customName, 'Salary');
      },
    );

    test(
      'C02: seeded row shows Archive affordance regardless of usage',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        // Seeded + unreferenced must still be Archive (risk #3).
        when(() => repo.isReferenced(1)).thenAnswer((_) async => false);

        rowsCtrl.add([
          _c(id: 1, type: CategoryType.expense, l10nKey: 'category.food'),
        ]);
        final state = await waitForData(container) as CategoriesData;
        expect(state.expense.single.affordance, CategoryRowAffordance.archive);
      },
    );

    test('C03: custom unreferenced row shows Delete', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      when(() => repo.isReferenced(5)).thenAnswer((_) async => false);
      rowsCtrl.add([
        _c(id: 5, type: CategoryType.expense, customName: 'Groceries'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.single.affordance, CategoryRowAffordance.delete);
    });

    test('C04: custom referenced row shows Archive', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      when(() => repo.isReferenced(7)).thenAnswer((_) async => true);
      rowsCtrl.add([
        _c(id: 7, type: CategoryType.expense, customName: 'Hobby'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.single.affordance, CategoryRowAffordance.archive);
    });

    test('C05: archived rows are excluded', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      // Even though `watchAll(includeArchived: false)` should filter at
      // the repo layer, the controller defensively skips `isArchived`
      // rows too so stale emissions don't leak past archive flows.
      rowsCtrl.add([
        _c(
          id: 1,
          type: CategoryType.expense,
          customName: 'A',
          isArchived: true,
        ),
        _c(id: 2, type: CategoryType.expense, customName: 'B'),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.map((v) => v.category.id), [2]);
    });

    test(
      'C06: expense/income rows are grouped into the matching section',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        rowsCtrl.add([
          _c(id: 1, type: CategoryType.expense, customName: 'A'),
          _c(id: 2, type: CategoryType.income, customName: 'B'),
          _c(id: 3, type: CategoryType.expense, customName: 'C'),
        ]);
        final state = await waitForData(container) as CategoriesData;
        expect(state.expense.map((v) => v.category.id), [1, 3]);
        expect(state.income.map((v) => v.category.id), [2]);
      },
    );

    test('C07: sort by sortOrder asc, nulls last, then display name', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      rowsCtrl.add([
        _c(id: 1, type: CategoryType.expense, customName: 'Zebra'),
        _c(id: 2, type: CategoryType.expense, customName: 'Beta', sortOrder: 1),
        _c(
          id: 3,
          type: CategoryType.expense,
          customName: 'Alpha',
          sortOrder: 0,
        ),
      ]);
      final state = await waitForData(container) as CategoriesData;
      expect(state.expense.map((v) => v.category.id), [3, 2, 1]);
    });

    test('C08: createCategory delegates to repo.save with id=0', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final draft = _c(id: 99, type: CategoryType.expense, customName: 'New');
      final saved = draft.copyWith(id: 42);
      when(() => repo.save(any())).thenAnswer((_) async => saved);

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .createCategory(draft);

      expect(outcome, const SaveCategoryOutcome.ok());
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(captured.id, 0);
      expect(captured.customName, 'New');
    });

    test('C09: renameCategory delegates to repo.rename', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final after = _c(id: 7, type: CategoryType.expense, customName: 'X');
      when(() => repo.rename(7, 'X')).thenAnswer((_) async => after);

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .renameCategory(7, 'X');
      expect(outcome, const SaveCategoryOutcome.ok());
      verify(() => repo.rename(7, 'X')).called(1);
    });

    test('C10: archiveCategory delegates to repo.archive', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final archived = _c(
        id: 3,
        type: CategoryType.expense,
        customName: 'Y',
        isArchived: true,
      );
      when(() => repo.archive(3)).thenAnswer((_) async => archived);

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .archiveCategory(3);
      expect(outcome, const ArchiveCategoryOutcome.ok());
      verify(() => repo.archive(3)).called(1);
    });

    test('C11: undoArchive writes isArchived=false via save', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final stored = _c(
        id: 4,
        type: CategoryType.expense,
        customName: 'Z',
        isArchived: true,
      );
      when(() => repo.getById(4)).thenAnswer((_) async => stored);
      when(() => repo.save(any()))
          .thenAnswer((_) async => stored.copyWith(isArchived: false));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .undoArchive(4);

      expect(outcome, const UndoArchiveCategoryOutcome.ok());
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(captured.id, 4);
      expect(captured.isArchived, isFalse);
    });

    test(
      'C12: deleteCategory returns inUse for CategoryInUseException',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        rowsCtrl.add(const []);
        await waitForData(container);

        when(() => repo.delete(11)).thenThrow(const CategoryInUseException(11));

        final outcome = await container
            .read(categoriesControllerProvider.notifier)
            .deleteCategory(11);
        expect(outcome, const DeleteCategoryOutcome.inUse());
      },
    );

    test('C12b: deleteCategory returns ok when the row is deleted', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.delete(11)).thenAnswer((_) async => true);

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .deleteCategory(11);
      expect(outcome, const DeleteCategoryOutcome.ok());
    });

    test(
      'C12c: deleteCategory returns ok when the row is already gone',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        rowsCtrl.add(const []);
        await waitForData(container);

        when(() => repo.delete(11)).thenAnswer((_) async => false);

        final outcome = await container
            .read(categoriesControllerProvider.notifier)
            .deleteCategory(11);
        expect(outcome, const DeleteCategoryOutcome.ok());
      },
    );

    test('C12d: deleteCategory returns failed on other failures', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.delete(11)).thenThrow(
        const CategoryRepositoryException(
          'Seeded category 11 cannot be deleted',
        ),
      );

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .deleteCategory(11);
      expect(outcome, const DeleteCategoryOutcome.failed());
    });

    test('C13: createCategory returns failed when save throws', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.save(any())).thenThrow(
        const CategoryRepositoryException(
          'Insert disappeared before read-back',
        ),
      );

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .createCategory(
            _c(id: 1, type: CategoryType.income, customName: 'X'),
          );
      expect(outcome, const SaveCategoryOutcome.failed());
    });

    test('C13b: updateIconColor returns failed when save throws, even for a '
        'type lock', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.getById(5)).thenAnswer(
        (_) async => _c(id: 5, type: CategoryType.expense, customName: 'A'),
      );
      // Synthetic: the stored type is copied, so save never type-locks.
      when(() => repo.save(any()))
          .thenThrow(const CategoryTypeLockedException(5));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .updateIconColor(id: 5, icon: 'home', color: 1);
      expect(outcome, const SaveCategoryOutcome.failed());
    });

    test('C13c: archiveCategory returns hasActiveRecurringRule for '
        'CategoryHasRecurringRuleException', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.archive(7))
          .thenThrow(const CategoryHasRecurringRuleException(7));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .archiveCategory(7);
      expect(outcome, const ArchiveCategoryOutcome.hasActiveRecurringRule());
    });

    test('C13d: renameCategory returns failed when rename throws', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.rename(8, 'B'))
          .thenThrow(const CategoryRepositoryException('Category 8 not found'));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .renameCategory(8, 'B');
      expect(outcome, const SaveCategoryOutcome.failed());
    });

    test('C13e: archiveCategory returns failed on other failures', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.archive(7))
          .thenThrow(const CategoryRepositoryException('Category 7 not found'));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .archiveCategory(7);
      expect(outcome, const ArchiveCategoryOutcome.failed());
    });

    test(
      'C13f: updateIconColor returns failed when the row is missing',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        rowsCtrl.add(const []);
        await waitForData(container);

        when(() => repo.getById(5)).thenAnswer((_) async => null);

        final outcome = await container
            .read(categoriesControllerProvider.notifier)
            .updateIconColor(id: 5, icon: 'home', color: 1);
        expect(outcome, const SaveCategoryOutcome.failed());
        verifyNever(() => repo.save(any()));
      },
    );

    test(
      'C13g: undoArchive returns ok and writes nothing when the row is missing',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(categoriesControllerProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);
        rowsCtrl.add(const []);
        await waitForData(container);

        when(() => repo.getById(4)).thenAnswer((_) async => null);

        final outcome = await container
            .read(categoriesControllerProvider.notifier)
            .undoArchive(4);
        expect(outcome, const UndoArchiveCategoryOutcome.ok());
        verifyNever(() => repo.save(any()));
      },
    );

    test('C13h: undoArchive returns failed when save throws', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.getById(4)).thenAnswer(
        (_) async => _c(
          id: 4,
          type: CategoryType.expense,
          customName: 'Z',
          isArchived: true,
        ),
      );
      when(() => repo.save(any()))
          .thenThrow(const CategoryRepositoryException('Category 4 not found'));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .undoArchive(4);
      expect(outcome, const UndoArchiveCategoryOutcome.failed());
    });

    test('C14: reorder passes the new order to repo.reorder', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.reorder([20, 10])).thenAnswer((_) async {});

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .reorder([20, 10]);

      expect(outcome, const ReorderCategoriesOutcome.ok());
      verify(() => repo.reorder([20, 10])).called(1);
    });

    test('C14b: reorder returns failed when repo.reorder throws', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      when(() => repo.reorder([20, 10])).thenThrow(Exception('injected'));

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .reorder([20, 10]);
      expect(outcome, const ReorderCategoriesOutcome.failed());
    });

    test('C14c: a command on a disposed controller returns failed instead of '
        'throwing', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      final sub = container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);
      final notifier = container.read(categoriesControllerProvider.notifier);

      // The screen closed: the auto-dispose controller is gone.
      sub.close();
      await container.pump();

      final outcome = await notifier.updateIconColor(
        id: 5,
        icon: 'home',
        color: 1,
      );
      expect(outcome, const SaveCategoryOutcome.failed());
      verifyNever(() => repo.getById(any()));
    });

    test('C15: updateIconColor preserves other fields', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(categoriesControllerProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      rowsCtrl.add(const []);
      await waitForData(container);

      final existing = _c(
        id: 50,
        type: CategoryType.expense,
        customName: 'Name',
      );
      when(() => repo.getById(50)).thenAnswer((_) async => existing);
      when(() => repo.save(any()))
          .thenAnswer((inv) async => inv.positionalArguments.first as Category);

      final outcome = await container
          .read(categoriesControllerProvider.notifier)
          .updateIconColor(id: 50, icon: 'home', color: 3);

      expect(outcome, const SaveCategoryOutcome.ok());
      final captured =
          verify(() => repo.save(captureAny())).captured.single as Category;
      expect(captured.id, 50);
      expect(captured.icon, 'home');
      expect(captured.color, 3);
      expect(captured.customName, 'Name');
      expect(captured.type, CategoryType.expense);
    });
  });
}

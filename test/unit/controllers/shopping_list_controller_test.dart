// ShoppingListController unit tests — Task 4.
//
// Covers:
//   - loading → data when stream emits items
//   - loading → empty when stream emits empty list
//   - stream error becomes ShoppingListError
//   - deleteItem hides row immediately and starts undo window
//   - undoDelete cancels timer; repo.delete never called
//   - timer expiry calls repo.delete
//   - failed delete fires ShoppingListDeleteFailedEffect and restores hidden row
//   - second delete commits first, opens new window
//   - canOpenItem is false while pending delete is active
//   - controller remains alive after simulated tab switch

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/data/models/shopping_list_item.dart';
import 'package:ledgerly/data/repositories/shopping_list_repository.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_controller.dart';
import 'package:ledgerly/features/shopping_list/shopping_list_state.dart';

class _MockShoppingListRepository extends Mock
    implements ShoppingListRepository {}

ShoppingListItem _item({
  required int id,
  int categoryId = 1,
  int accountId = 1,
  String? memo,
}) => ShoppingListItem(
  id: id,
  categoryId: categoryId,
  accountId: accountId,
  memo: memo,
  draftDate: DateTime(2026, 5, 1),
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

void main() {
  group('ShoppingListController', () {
    late _MockShoppingListRepository repo;
    late StreamController<List<ShoppingListItem>> itemsCtrl;

    setUp(() {
      repo = _MockShoppingListRepository();
      itemsCtrl = StreamController<List<ShoppingListItem>>.broadcast();

      when(() => repo.watchAll()).thenAnswer((_) => itemsCtrl.stream);
    });

    tearDown(() async {
      await itemsCtrl.close();
    });

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [shoppingListRepositoryProvider.overrideWithValue(repo)],
      );
    }

    Future<ShoppingListState> waitFor(
      ProviderContainer c,
      bool Function(ShoppingListState) accept,
    ) async {
      for (var i = 0; i < 200; i++) {
        final s = c.read(shoppingListControllerProvider);
        if (s is AsyncData<ShoppingListState> && accept(s.value)) {
          return s.value;
        }
        await Future<void>.delayed(Duration.zero);
      }
      throw StateError('ShoppingListController never produced expected state');
    }

    Future<void> pump() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    test('SLC01: loading → data when stream emits items', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(shoppingListControllerProvider, (_, _) {});

      expect(
        container.read(shoppingListControllerProvider),
        isA<AsyncLoading<ShoppingListState>>(),
      );

      final item = _item(id: 1);
      await Future<void>.delayed(Duration.zero);
      itemsCtrl.add([item]);

      final state = await waitFor(container, (s) => s is ShoppingListData);
      final data = state as ShoppingListData;
      expect(data.items, hasLength(1));
      expect(data.items.first.id, 1);
      expect(data.pendingDelete, isNull);
    });

    test('SLC02: loading → empty when stream emits empty list', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(shoppingListControllerProvider, (_, _) {});

      expect(
        container.read(shoppingListControllerProvider),
        isA<AsyncLoading<ShoppingListState>>(),
      );

      await Future<void>.delayed(Duration.zero);
      itemsCtrl.add(const []);

      final state = await waitFor(container, (s) => s is ShoppingListEmpty);
      expect(state, isA<ShoppingListEmpty>());
    });

    test('SLC03: stream error becomes ShoppingListError', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(shoppingListControllerProvider, (_, _) {});

      final error = StateError('boom');
      await Future<void>.delayed(Duration.zero);
      itemsCtrl.addError(error, StackTrace.current);

      final state = await waitFor(container, (s) => s is ShoppingListError);
      expect((state as ShoppingListError).error, error);
    });

    test(
      'SLC04: deleteItem hides row immediately and starts undo window',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(shoppingListControllerProvider, (_, _) {});

        when(() => repo.delete(any())).thenAnswer((_) async => true);

        final item = _item(id: 42);
        await Future<void>.delayed(Duration.zero);
        itemsCtrl.add([item]);
        await waitFor(container, (s) => s is ShoppingListData);

        fakeAsync((async) {
          container
              .read(shoppingListControllerProvider.notifier)
              .deleteItem(42);
          async.flushMicrotasks();

          final data =
              container.read(shoppingListControllerProvider).requireValue
                  as ShoppingListData;
          expect(data.pendingDelete!.itemId, 42);
          expect(data.items, isEmpty); // hidden visually
          verifyNever(() => repo.delete(any()));

          async.elapse(kUndoWindow + const Duration(milliseconds: 1));
          async.flushMicrotasks();
        });

        verify(() => repo.delete(42)).called(1);
      },
    );

    test('SLC05: undoDelete cancels timer; repo.delete never called', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(shoppingListControllerProvider, (_, _) {});

      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final item = _item(id: 99);
      await Future<void>.delayed(Duration.zero);
      itemsCtrl.add([item]);
      await waitFor(container, (s) => s is ShoppingListData);

      fakeAsync((async) {
        container.read(shoppingListControllerProvider.notifier).deleteItem(99);
        async.flushMicrotasks();
        container.read(shoppingListControllerProvider.notifier).undoDelete();
        async.flushMicrotasks();
        async.elapse(kUndoWindow + const Duration(milliseconds: 1));
        async.flushMicrotasks();
      });

      verifyNever(() => repo.delete(any()));
      final after = await waitFor(
        container,
        (s) => s is ShoppingListData && s.pendingDelete == null,
      );
      expect((after as ShoppingListData).pendingDelete, isNull);
      expect(after.items, [item]);
    });

    test('SLC06: timer expiry calls repo.delete', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(shoppingListControllerProvider, (_, _) {});

      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final item = _item(id: 7);
      await Future<void>.delayed(Duration.zero);
      itemsCtrl.add([item]);
      await waitFor(container, (s) => s is ShoppingListData);

      fakeAsync((async) {
        container.read(shoppingListControllerProvider.notifier).deleteItem(7);
        async.flushMicrotasks();
        async.elapse(kUndoWindow + const Duration(milliseconds: 1));
        async.flushMicrotasks();
      });

      verify(() => repo.delete(7)).called(1);
    });

    test(
      'SLC07: failed delete fires ShoppingListDeleteFailedEffect and restores hidden row',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(shoppingListControllerProvider, (_, _) {});

        final effects = <ShoppingListEffect>[];
        container
            .read(shoppingListControllerProvider.notifier)
            .setEffectListener(effects.add);

        when(
          () => repo.delete(any()),
        ).thenAnswer((_) async => throw StateError('db error'));

        final item = _item(id: 55);
        await Future<void>.delayed(Duration.zero);
        itemsCtrl.add([item]);
        await waitFor(container, (s) => s is ShoppingListData);

        fakeAsync((fake) {
          container
              .read(shoppingListControllerProvider.notifier)
              .deleteItem(55);
          fake.flushMicrotasks();

          final hiding =
              container.read(shoppingListControllerProvider).requireValue
                  as ShoppingListData;
          expect(hiding.pendingDelete?.itemId, 55);
          expect(hiding.items, isEmpty);

          // Advance past the undo window so the timer fires and calls
          // repo.delete(55), which throws → effect fires + row restores.
          fake.elapse(kUndoWindow + const Duration(milliseconds: 1));
          fake.flushMicrotasks();
        });

        // After fakeAsync exits, await the async repo.delete throw propagation.
        await pump();

        final recovered = await waitFor(
          container,
          (s) =>
              s is ShoppingListData &&
              s.pendingDelete == null &&
              s.items.length == 1,
        );

        expect((recovered as ShoppingListData).items, [item]);
        expect(effects.single, isA<ShoppingListDeleteFailedEffect>());
        verify(() => repo.delete(55)).called(1);
      },
    );

    test('SLC08: second delete commits first, opens new window', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      container.listen(shoppingListControllerProvider, (_, _) {});

      when(() => repo.delete(any())).thenAnswer((_) async => true);

      final item1 = _item(id: 1);
      final item2 = _item(id: 2);
      await Future<void>.delayed(Duration.zero);
      itemsCtrl.add([item1, item2]);
      await waitFor(container, (s) => s is ShoppingListData);

      fakeAsync((async) {
        container.read(shoppingListControllerProvider.notifier).deleteItem(1);
        async.flushMicrotasks();

        container.read(shoppingListControllerProvider.notifier).deleteItem(2);
        async.flushMicrotasks();

        // First delete should have committed immediately.
        verify(() => repo.delete(1)).called(1);
        verifyNever(() => repo.delete(2));

        async.elapse(kUndoWindow + const Duration(milliseconds: 1));
        async.flushMicrotasks();
      });

      verify(() => repo.delete(2)).called(1);
    });

    test(
      'SLC09: canOpenItem is false while pending delete is active',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);
        container.listen(shoppingListControllerProvider, (_, _) {});

        when(() => repo.delete(any())).thenAnswer((_) async => true);

        final item = _item(id: 10);
        await Future<void>.delayed(Duration.zero);
        itemsCtrl.add([item]);
        await waitFor(container, (s) => s is ShoppingListData);

        final controller = container.read(
          shoppingListControllerProvider.notifier,
        );
        expect(controller.canOpenItem, isTrue);

        fakeAsync((async) {
          controller.deleteItem(10);
          async.flushMicrotasks();

          expect(controller.canOpenItem, isFalse);

          controller.undoDelete();
          async.flushMicrotasks();
        });

        expect(controller.canOpenItem, isTrue);
      },
    );

    test(
      'SLC10: controller remains alive after simulated tab switch (provider not disposed while listener exists)',
      () async {
        final container = makeContainer();
        addTearDown(container.dispose);

        // Subscribe once to simulate the screen being active.
        final sub1 = container.listen(
          shoppingListControllerProvider,
          (_, _) {},
        );

        final item = _item(id: 1);
        await Future<void>.delayed(Duration.zero);
        itemsCtrl.add([item]);
        await waitFor(container, (s) => s is ShoppingListData);

        // Simulate a second tab becoming active — a new listener is added
        // before the first is removed (IndexedStack keeps both in the tree).
        final sub2 = container.listen(
          shoppingListControllerProvider,
          (_, _) {},
        );

        // Close the first listener (simulating the old tab going off-screen).
        sub1.close();

        // The provider should still be alive because sub2 holds a reference.
        final state = container.read(shoppingListControllerProvider);
        expect(state, isA<AsyncData<ShoppingListState>>());
        expect((state.requireValue as ShoppingListData).items, hasLength(1));

        sub2.close();
      },
    );
  });
}

// `showCategoryIconPicker` widget tests (issue #103).
//
// Covers:
//   - The sheet takes 90% of the screen height.
//   - Icons sit under one header per `IconGroup`, in `kIconGroups` order,
//     with localized titles.
//   - Tapping an icon resolves the `Future` with its registry key.
//   - The selected key is outlined.
//   - Each icon is drawn in its group's seeded category colour on a
//     15%-alpha circle of the same colour.
//   - Headers grow with 2× text scale without overflowing.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ledgerly/core/utils/color_palette.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/features/categories/views/category_icon_picker.dart';

const _enHeaders = <String>[
  'Food',
  'Drinks',
  'Transportation',
  'Shopping',
  'Entertainment',
  'Housing',
  '3C',
  'Medical',
  'Income',
  'Other',
];

Future<void> _openPicker(
  WidgetTester tester, {
  String? selected,
  void Function(String?)? onPicked,
  Size size = const Size(400, 800),
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final picked = await showCategoryIconPicker(
                  ctx,
                  selected: selected,
                );
                onPicked?.call(picked);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('I01: the sheet takes 90% of the screen height', (tester) async {
    await _openPicker(tester);

    expect(
      tester.getSize(find.byType(BottomSheet)).height,
      closeTo(800 * 0.9, 1),
    );
  });

  testWidgets('I02: group headers appear in order', (tester) async {
    // Tall surface so every sliver is laid out at once.
    await _openPicker(tester, size: const Size(400, 4000));

    final tops = [
      for (final h in _enHeaders) tester.getTopLeft(find.text(h)).dy,
    ];
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]), reason: _enHeaders[i]);
    }
    // Each group's icons sit between its header and the next one.
    final wineBar = tester.getTopLeft(find.byIcon(Icons.wine_bar)).dy;
    expect(wineBar, greaterThan(tops[1]));
    expect(wineBar, lessThan(tops[2]));
  });

  testWidgets('I03: headers are localized (zh_TW)', (tester) async {
    await _openPicker(
      tester,
      size: const Size(400, 4000),
      locale: const Locale('zh', 'TW'),
    );

    for (final h in [
      '食物',
      '飲品',
      '交通',
      '消費',
      '娛樂',
      '居家',
      '3C',
      '醫藥',
      '收入',
      '其他',
    ]) {
      expect(find.text(h), findsOneWidget, reason: h);
    }
  });

  testWidgets('I04: tapping an icon resolves with its key', (tester) async {
    String? picked;
    await _openPicker(tester, onPicked: (k) => picked = k);

    await tester.tap(find.byIcon(Icons.wine_bar));
    await tester.pumpAndSettle();

    expect(picked, 'wine_bar');
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('I05: the selected icon is outlined', (tester) async {
    await _openPicker(tester, selected: 'wine_bar');

    BoxBorder? borderOf(IconData icon) {
      final boxes = tester.widgetList<Container>(
        find.ancestor(of: find.byIcon(icon), matching: find.byType(Container)),
      );
      return boxes
          .map((c) => (c.decoration as BoxDecoration?)?.border)
          .nonNulls
          .firstOrNull;
    }

    expect(borderOf(Icons.wine_bar), isNotNull);
    expect(borderOf(Icons.local_cafe), isNull);
  });

  testWidgets('I07: icons take their group colour', (tester) async {
    await _openPicker(tester);

    void expectTint(IconData icon, int paletteIndex) {
      final color = colorForIndex(paletteIndex);
      expect(tester.widget<Icon>(find.byIcon(icon)).color, color);
      final circle = tester.widget<Container>(
        find
            .ancestor(of: find.byIcon(icon), matching: find.byType(Container))
            .first,
      );
      final deco = circle.decoration! as BoxDecoration;
      expect(deco.shape, BoxShape.circle);
      expect(deco.color, color.withValues(alpha: 0.15));
    }

    expectTint(Icons.restaurant, CategoryPaletteIndex.red60);
    expectTint(Icons.wine_bar, CategoryPaletteIndex.green40);
    expectTint(Icons.directions_bus, CategoryPaletteIndex.cyan70);
  });

  testWidgets('I06: headers grow at 2× text scale without overflow', (
    tester,
  ) async {
    await _openPicker(tester);
    final normal = tester.getSize(find.text('Food')).height;
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await _openPicker(tester, textScaler: const TextScaler.linear(2));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.text('Food')).height, greaterThan(normal * 1.5));
  });
}

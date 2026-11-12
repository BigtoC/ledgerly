import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/core/l10n/app_localizations_delegates.dart';
import 'package:ledgerly/domain/models/category.dart';
import 'package:ledgerly/l10n/app_localizations.dart';
import 'package:ledgerly/ui/core/theme/app_theme.dart';
import 'package:ledgerly/ui/features/categories/view_models/categories_state.dart';
import 'package:ledgerly/ui/features/categories/views/category_tile.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // flutter_slidable must be on the app's Material copy (material_ui).
  // An action on the framework copy cannot see the app's Theme and falls
  // back to an English-script ThemeData, so a zh_TW label loses the
  // localized typography.
  testWidgets('swipe action label uses the app theme typography (zh_TW)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('zh', 'TW'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CategoryTile(
            view: const CategoryRowView(
              category: Category(
                id: 1,
                icon: 'category',
                color: 0,
                type: CategoryType.expense,
                customName: 'Food',
              ),
              affordance: CategoryRowAffordance.delete,
            ),
            index: 0,
            onTap: () {},
            onArchive: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CategoryTile), const Offset(-400, 0));
    await tester.pumpAndSettle();

    final label = tester.widget<RichText>(
      find
          .descendant(
            of: find.byType(SlidableAction),
            matching: find.byType(RichText),
          )
          .last,
    );
    expect(label.text.style?.textBaseline, TextBaseline.ideographic);
  });
}

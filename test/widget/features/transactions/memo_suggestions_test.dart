// Widget tests for `MemoSuggestions` and its interplay with `MemoField`:
// chips render the provider's memos, render nothing when empty, and a
// tap fills the memo with the cursor placed at the end.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/features/transactions/transactions_providers.dart';
import 'package:ledgerly/features/transactions/widgets/memo_field.dart';
import 'package:ledgerly/features/transactions/widgets/memo_suggestions.dart';
import 'package:ledgerly/l10n/app_localizations.dart';

/// Hosts a MemoField + MemoSuggestions pair the way the form screen does:
/// both read and write one memo value.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String memo = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MemoField(
          initialValue: memo,
          onChanged: (v) => setState(() => memo = v),
        ),
        MemoSuggestions(
          categoryId: 7,
          onSelected: (v) => setState(() => memo = v),
        ),
      ],
    );
  }
}

Widget _mount(List<String> memos) {
  return ProviderScope(
    overrides: [
      txMemoSuggestionsProvider(7).overrideWith((ref) => Stream.value(memos)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: _Host()),
    ),
  );
}

void main() {
  testWidgets('renders one chip per memo, in order', (tester) async {
    await tester.pumpWidget(_mount(const ['Lunch', 'Coffee']));
    await tester.pump();

    final chips = tester.widgetList<ActionChip>(find.byType(ActionChip));
    expect(chips, hasLength(2));
    expect(find.widgetWithText(ActionChip, 'Lunch'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Coffee'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Lunch')).dx,
      lessThan(tester.getTopLeft(find.text('Coffee')).dx),
    );
  });

  testWidgets('renders nothing when the category has no memos', (tester) async {
    await tester.pumpWidget(_mount(const []));
    await tester.pump();

    expect(find.byType(ActionChip), findsNothing);
  });

  testWidgets('tapping a chip fills the memo with the cursor at the end', (
    tester,
  ) async {
    await tester.pumpWidget(_mount(const ['Lunch']));
    await tester.pump();

    await tester.tap(find.widgetWithText(ActionChip, 'Lunch'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Lunch');
    expect(
      field.controller!.selection,
      const TextSelection.collapsed(offset: 5),
    );
  });

  testWidgets('long memos stay on one line at 2x text scale', (tester) async {
    const longMemo =
        'A very long memo that would not fit on a single chip at all';
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _mount(const [longMemo, 'Coffee']),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.text(longMemo));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}

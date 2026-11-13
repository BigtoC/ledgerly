// `showMemoPickerSheet` — bottom sheet listing every memo used in a
// category, newest first. Opened from the "More" chip in
// `MemoSuggestions`. Resolves with the picked suggestion (memo and its
// account), or null on dismiss.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../view_models/transactions_providers.dart';

Future<MemoSuggestion?> showMemoPickerSheet(
  BuildContext context,
  int categoryId,
) {
  return showModalBottomSheet<MemoSuggestion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.88,
      child: _MemoPickerSheet(categoryId: categoryId),
    ),
  );
}

class const _MemoPickerSheet({required final int categoryId})
    extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memos =
        ref.watch(txAllMemosProvider(categoryId)).value ??
        const <MemoSuggestion>[];

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.txMemoPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: memos.length,
              separatorBuilder: (context, index) => const FractionallySizedBox(
                widthFactor: 0.88,
                child: Divider(height: 1),
              ),
              itemBuilder: (context, index) {
                final suggestion = memos[index];
                return ListTile(
                  title: Text(suggestion.memo),
                  onTap: () => Navigator.of(context).pop(suggestion),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

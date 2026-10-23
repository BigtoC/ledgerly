// `MemoSuggestions` — chips under the MemoField listing memos recently
// used in the selected category. Tapping a chip fills the memo. When the
// category has more than `memoSuggestionLimit` memos, a trailing "More"
// chip opens a sheet listing all of them. Renders nothing while loading,
// on error, or when the category has no memos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../transactions_providers.dart';
import 'memo_picker_sheet.dart';

class MemoSuggestions extends ConsumerWidget {
  const MemoSuggestions({
    super.key,
    required this.categoryId,
    required this.onSelected,
  });

  final int categoryId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memos =
        ref.watch(txMemoSuggestionsProvider(categoryId)).value ??
        const <String>[];
    if (memos.isEmpty) return const SizedBox.shrink();
    final hasMore = memos.length > memoSuggestionLimit;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (final memo in memos.take(memoSuggestionLimit))
              ActionChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    memo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onPressed: () => onSelected(memo),
              ),
            if (hasMore)
              ActionChip(
                label: Text(AppLocalizations.of(context).txMemoSuggestionsMore),
                onPressed: () async {
                  final memo = await showMemoPickerSheet(context, categoryId);
                  if (memo != null) onSelected(memo);
                },
              ),
          ],
        ),
      ),
    );
  }
}

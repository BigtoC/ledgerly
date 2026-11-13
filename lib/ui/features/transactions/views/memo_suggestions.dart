// `MemoSuggestions` — chips under the MemoField listing memos recently
// used in the selected category. Tapping a chip hands over the memo and
// its account; the form fills the memo and switches to that account
// (issue #152). The chips show only the memo text. When the
// category has more than `memoSuggestionLimit` memos, a trailing "More"
// chip opens a sheet listing all of them. Renders nothing while loading,
// on error, or when the category has no memos.

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../view_models/transactions_providers.dart';
import 'memo_picker_sheet.dart';

class const MemoSuggestions({
  super.key,
  required final int categoryId,
  required final ValueChanged<MemoSuggestion> onSelected,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memos =
        ref.watch(txMemoSuggestionsProvider(categoryId)).value ??
        const <MemoSuggestion>[];
    if (memos.isEmpty) return const SizedBox.shrink();
    final hasMore = memos.length > memoSuggestionLimit;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (final suggestion in memos.take(memoSuggestionLimit))
              ActionChip(
                label: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    suggestion.memo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onPressed: () => onSelected(suggestion),
              ),
            if (hasMore)
              ActionChip(
                label: Text(AppLocalizations.of(context).txMemoSuggestionsMore),
                onPressed: () async {
                  final picked = await showMemoPickerSheet(context, categoryId);
                  if (picked != null) onSelected(picked);
                },
              ),
          ],
        ),
      ),
    );
  }
}

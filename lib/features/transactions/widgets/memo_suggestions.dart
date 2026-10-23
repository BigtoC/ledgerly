// `MemoSuggestions` — chips under the MemoField listing memos recently
// used in the selected category. Tapping a chip fills the memo. Renders
// nothing while loading, on error, or when the category has no memos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../transactions_providers.dart';

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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (final memo in memos)
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
          ],
        ),
      ),
    );
  }
}

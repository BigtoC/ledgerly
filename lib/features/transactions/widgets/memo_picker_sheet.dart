// `showMemoPickerSheet` — bottom sheet listing every memo used in a
// category, newest first. Opened from the "More" chip in
// `MemoSuggestions`. Resolves with the picked memo, or null on dismiss.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../transactions_providers.dart';

Future<String?> showMemoPickerSheet(BuildContext context, int categoryId) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => FractionallySizedBox(
      heightFactor: 0.6,
      child: _MemoPickerSheet(categoryId: categoryId),
    ),
  );
}

class _MemoPickerSheet extends ConsumerWidget {
  const _MemoPickerSheet({required this.categoryId});

  final int categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final memos =
        ref.watch(txAllMemosProvider(categoryId)).value ?? const <String>[];

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
            child: ListView.builder(
              itemCount: memos.length,
              itemBuilder: (context, index) {
                final memo = memos[index];
                return ListTile(
                  title: Text(memo),
                  onTap: () => Navigator.of(context).pop(memo),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

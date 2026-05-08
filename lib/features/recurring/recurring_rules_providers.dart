import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/repository_providers.dart';
import '../../data/models/account.dart';

part 'recurring_rules_providers.g.dart';

final recurringActiveAccountsProvider =
    StreamProvider.autoDispose<List<Account>>((ref) {
      final repo = ref.watch(accountRepositoryProvider);
      return repo.watchAll();
    });

/// Returns the count of pending items for a given rule.
/// Used by the form screen's inline notice. Reads
/// PendingTransactionRepository directly — no need to proxy through
/// RecurringRulesRepository.
@Riverpod(dependencies: [pendingTransactionRepository])
Future<int> pendingCountForRule(Ref ref, int ruleId) {
  return ref
      .watch(pendingTransactionRepositoryProvider)
      .countByRecurringRule(ruleId);
}

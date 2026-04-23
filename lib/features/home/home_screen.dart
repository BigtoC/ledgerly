// TODO(M5): Home screen per PRD -> MVP Screens + Layout Primitives.
// Home shows ONE day at a time (not an infinite day-list). Required widget tree:
//
//   CustomScrollView
//     ├─ SliverToBoxAdapter  — currency-grouped summary strip
//     ├─ SliverToBoxAdapter  — day-nav header (prev ◀  {selectedDate}  ▶ next)
//     ├─ SliverList          — transaction rows for the selected day
//     └─ SliverPadding       — bottom FAB clearance
//
// Controller composes `TransactionRepository.watchDaysWithActivity()` with
// `watchByDay(selectedDay)`; prev/next walks across days-with-activity.
// NEVER nest a ListView inside a Column. No groupBy / fold / NumberFormat /
// DateFormat in build() — HomeController owns presentation transformation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: const Center(child: Text('Home')),
    );
  }
}

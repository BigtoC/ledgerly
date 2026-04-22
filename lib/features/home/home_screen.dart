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

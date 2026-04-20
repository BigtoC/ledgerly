// TODO(M5): Home screen per PRD -> MVP Screens + Layout Primitives.
// Required widget tree:
//
//   CustomScrollView
//     ├─ SliverToBoxAdapter  — currency-grouped summary strip
//     ├─ SliverList          — day headers + transaction rows
//     └─ SliverPadding       — bottom FAB clearance
//
// NEVER nest a ListView inside a Column. No groupBy / fold / NumberFormat /
// DateFormat in build() — HomeController owns presentation transformation.

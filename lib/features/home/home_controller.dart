// TODO(M5): `HomeController` consumes `Stream<List<Transaction>>` from
// `TransactionRepository` and emits
//   `HomeState.data(daysGroupedByDate, summariesByCurrency, pendingBadgeCount)`
// so the widget renders without any transformation per PRD -> Controller
// Responsibilities.

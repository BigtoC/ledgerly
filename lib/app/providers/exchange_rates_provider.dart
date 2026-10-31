import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'repository_providers.dart';

part 'exchange_rates_provider.g.dart';

/// Stream of the exchange-rate snapshot map (scaled-e9 integer values
/// keyed by `from→to`). Consumed by UI tiles via `ref.watch`.
///
/// Lives outside `repository_providers.dart` so that widgets can read the
/// rates without importing the repository providers, which the layer
/// rules in `import_analysis_options.yaml` forbid them.
@Riverpod(keepAlive: true, dependencies: [exchangeRateRepository])
Stream<Map<String, int>> exchangeRates(Ref ref) {
  return ref.watch(exchangeRateRepositoryProvider).watchRates();
}

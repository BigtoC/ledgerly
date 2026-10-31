import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/csv_file_service.dart';
import '../../data/services/exchange_rate_service.dart';

part 'service_providers.g.dart';

// Service providers. Only app-layer providers that build repositories,
// use cases or the app-update check import this file. The layer rules in
// `import_analysis_options.yaml` forbid it everywhere under
// `lib/features/`, so features reach services only through a repository
// or a use case.

/// Shared HTTP client for every HTTP service. Conservative timeouts; the
/// client is closed when the owning container is disposed.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}

/// Exchange-rate HTTP service. Uses the shared [dioProvider] client.
@Riverpod(keepAlive: true, dependencies: [])
ExchangeRateService exchangeRateService(Ref ref) =>
    ExchangeRateService(ref.watch(dioProvider));

/// System file picker for CSV import. Tests override it with a fake that
/// returns fixture bytes.
@Riverpod(keepAlive: true, dependencies: [])
CsvFileService csvFileService(Ref ref) => CsvFileService();

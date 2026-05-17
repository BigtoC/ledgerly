import 'package:dio/dio.dart';

/// HTTP client for the Ledgerly conversion API.
///
/// Fetches exchange rates from the hosted Cloudflare Worker endpoint.
/// Returns raw parsed data as anonymous Dart records — the
/// `services_forbid_upstream_and_siblings` import rule forbids this
/// layer from importing `data/models/` or `data/repositories/`.
///
/// The endpoint URL is overridable via the [baseUrl] constructor parameter
/// so that staging/localhost dev and integration tests can target an
/// alternate host without mocking the entire Dio client. Currency codes
/// passed in [pairs] are validated against the ISO 4217 shape
/// (3 alphabetic chars) before being concatenated into the query string;
/// malformed codes are silently skipped to avoid corrupting the request.
///
/// **TLS / certificate pinning:** the Cloudflare Worker endpoint relies on
/// the OS-managed CA trust store. Exchange rates are advisory and rendered
/// with the `≈` qualifier; they are not used in financial settlement.
/// A MITM attacker who replaced the response would corrupt the displayed
/// total but not any persisted financial record. If the threat model later
/// expands, add certificate pinning at that point.
///
/// See `docs/superpowers/specs/2026-05-14-multi-currency-conversion-design.md`.
class ExchangeRateService {
  ExchangeRateService(this._dio, {String? baseUrl})
    : _baseUrl = baseUrl ?? _defaultBaseUrl;

  final Dio _dio;
  final String _baseUrl;

  static const _defaultBaseUrl = String.fromEnvironment('FOREX_API_URL');

  static final _iso4217 = RegExp(r'^[A-Za-z]{3}$');

  /// Fetches rates for the given currency pairs.
  ///
  /// [pairs] is a list of `(from, to)` records where each string is an
  /// ISO 4217 currency code. The method validates each code with
  /// `^[A-Za-z]{3}$`, builds the ticker query string (e.g. `hkdusd,eurusd`),
  /// calls the API, and returns successfully parsed entries. `from`/`to`
  /// are normalized to uppercase.
  ///
  /// Throws [DioException] on network or HTTP errors — the caller
  /// (repository) catches and logs only the exception type.
  Future<List<({String from, String to, double rate, DateTime fetchedAt})>>
  fetchRates(List<({String from, String to})> pairs) async {
    if (pairs.isEmpty) return const [];

    final validPairs = pairs
        .where((p) => _iso4217.hasMatch(p.from) && _iso4217.hasMatch(p.to))
        .toList();
    if (validPairs.isEmpty) return const [];

    final tickers = validPairs
        .map((p) => '${p.from.toLowerCase()}${p.to.toLowerCase()}')
        .join(',');

    final response = await _dio.get<List<dynamic>>(
      _baseUrl,
      queryParameters: {'tickers': tickers},
    );

    final data = response.data;
    if (data == null) return const [];

    final results =
        <({String from, String to, double rate, DateTime fetchedAt})>[];
    for (final entry in data) {
      if (entry is! Map<String, dynamic>) continue;
      final rate = entry['rate'];
      final from = entry['from'];
      final to = entry['to'];
      final fetchedAt = entry['fetched_at'];
      if (rate is! num || from is! String || to is! String) continue;
      if (!_iso4217.hasMatch(from) || !_iso4217.hasMatch(to)) continue;
      if (rate <= 0) continue;
      results.add((
        from: from.toUpperCase(),
        to: to.toUpperCase(),
        rate: rate.toDouble(),
        fetchedAt: fetchedAt is String
            ? DateTime.tryParse(fetchedAt) ?? DateTime.timestamp()
            : DateTime.timestamp(),
      ));
    }
    return results;
  }
}

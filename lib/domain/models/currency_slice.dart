import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency_slice.freezed.dart';

/// Per-currency total emitted by
/// `TransactionRepository.watchByCurrencyInRange`.
@freezed
abstract class CurrencySlice with _$CurrencySlice {
  const factory CurrencySlice({
    required String currencyCode,
    required int totalMinorUnits,
  }) = _CurrencySlice;
}

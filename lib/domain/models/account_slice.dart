import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_slice.freezed.dart';

/// Per-(account, currency) subtotal emitted by
/// `TransactionRepository.watchByAccountInRange`.
@freezed
abstract class AccountSlice with _$AccountSlice {
  const factory AccountSlice({
    required int accountId,
    required String currencyCode,
    required int totalMinorUnits,
  }) = _AccountSlice;
}

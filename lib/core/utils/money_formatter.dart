// TODO(M2): Format integer minor units into locale-aware display strings.
// Divides by 10^currencies.decimals and applies NumberFormat.currency
// from `intl`. This is the ONLY place `double` may appear near money.
//
// Tested against USD (2 decimals), JPY (0), ETH (18), TWD (2) in
// test/unit/utils/money_formatter_test.dart per PRD -> Money Storage Policy.

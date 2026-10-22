// Entry point for Ledgerly.
//
// Guardrail G9 (PRD clean-code guardrails): all `await` lives inside
// `bootstrap()`. `main` must stay tiny — a single `await bootstrap()` call.

import 'package:ledgerly/app/bootstrap.dart';
import 'package:ledgerly/app/providers/repository_providers.dart';
import 'package:ledgerly/app/router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

@Dependencies([router, exchangeRateRepository])
Future<void> main() async {
  await bootstrap();
}

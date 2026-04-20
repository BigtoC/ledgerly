// Entry point for Ledgerly.
//
// Guardrail G9 (PRD clean-code guardrails): all `await` lives inside
// `bootstrap()`. `main` must stay tiny — a single `await bootstrap()` call.

import 'package:ledgerly/app/bootstrap.dart';

Future<void> main() async {
  await bootstrap();
}

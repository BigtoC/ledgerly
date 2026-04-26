import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/database/app_database.dart';

part 'app_database_provider.g.dart';

// `dependencies: const []` tells riverpod_lint that this provider is
// scope-overridable (which is the only way it gets a value — see body) and
// has no transitive scopable deps. Without this, every override site fires
// `scoped_providers_should_specify_dependencies`.
@Riverpod(keepAlive: true, dependencies: [])
AppDatabase appDatabase(Ref ref) => throw UnimplementedError(
  'appDatabaseProvider must be overridden by bootstrap() or a test harness',
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/locale_service.dart';

part 'locale_service_provider.g.dart';

@Riverpod(keepAlive: true)
LocaleService localeService(Ref ref) => const LocaleService();

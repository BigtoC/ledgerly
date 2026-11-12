import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// `localizationsDelegates` for every `MaterialApp`.
///
/// Use this instead of `AppLocalizations.localizationsDelegates`: gen-l10n
/// still lists the deprecated `flutter_localizations` Material and Cupertino
/// delegates there (flutter/flutter#191072), and `package:material_ui`
/// widgets cannot read those.
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

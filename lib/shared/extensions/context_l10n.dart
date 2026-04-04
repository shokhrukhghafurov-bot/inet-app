import 'package:flutter/material.dart';
import 'package:inet_app/l10n/gen/app_localizations.dart';

extension ContextL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      AppLocalizations.localizationsDelegates;

  Iterable<Locale> get supportedLocales => AppLocalizations.supportedLocales;
}

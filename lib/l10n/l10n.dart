import 'package:flutter/material.dart';
import 'package:spotiflac/l10n/app_localizations.dart';
import 'package:spotiflac/utils/user_facing_error.dart';

export 'package:spotiflac/l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String friendlyError(
    Object? error, {
    String fallback = defaultUserFacingErrorMessage,
  }) => userFacingErrorMessage(error, fallback: fallback);
}

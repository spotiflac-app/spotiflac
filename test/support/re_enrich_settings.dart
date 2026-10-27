import 'package:spotiflac/models/settings.dart';
import 'package:spotiflac/providers/settings_provider.dart';

class ReEnrichTestSettings extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  @override
  Future<void> syncLyricsSettingsToBackend({AppSettings? settings}) async {}
}

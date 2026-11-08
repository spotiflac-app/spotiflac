import 'package:flutter/foundation.dart';

class AppInfo {
  static const String version = '5.3.1';
  static const String buildNumber = '167';

  /// The release whose What's New tour people see once after updating. Change
  /// it together with the tour's pages when a release earns a new one.
  static const String whatsNewRelease = '5.3';

  static const String gitCommit = String.fromEnvironment('GIT_COMMIT');
  static String get shortGitCommit =>
      gitCommit.length > 8 ? gitCommit.substring(0, 8) : gitCommit;

  /// The version shown to people; debug builds stay internal.
  static String get displayVersion => versionLabel();

  @visibleForTesting
  static String versionLabel({bool debug = kDebugMode}) =>
      debug ? 'Internal' : version;

  static const String appName = 'SpotiFLAC';
  static const String license = 'LGPL-3.0-only';
  static const String copyright = '© 2026 Zarz Eleutherius';

  static const String mobileAuthor = 'spotiflac-app';
  static const String websiteUrl = 'https://spotiflac.com';
  static const bool discordEnabled = bool.fromEnvironment(
    'SPOTIFLAC_DISCORD_ENABLED',
    defaultValue: true,
  );

  static const String githubRepo = String.fromEnvironment(
    'SPOTIFLAC_GITHUB_REPO',
    defaultValue: 'spotiflac-app/spotiflac',
  );
  static const String githubUrl = 'https://github.com/$githubRepo';

  /// Public downloads for every platform.
  static const String desktopGithubRepo = String.fromEnvironment(
    'SPOTIFLAC_DESKTOP_GITHUB_REPO',
    defaultValue: 'spotiflac-app/spotiflac-releases',
  );
  static const String remoteConfigApiUrl = String.fromEnvironment(
    'SPOTIFLAC_CONFIG_URL',
    defaultValue:
        'https://raw.githubusercontent.com/spotiflac-app/spotiflac-releases/main/config/app.json',
  );
}

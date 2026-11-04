import 'package:flutter/foundation.dart';
import 'package:spotiflac/utils/desktop_platform.dart';

class AppInfo {
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  static const String gitCommit = String.fromEnvironment('GIT_COMMIT');
  static String get shortGitCommit =>
      gitCommit.length > 8 ? gitCommit.substring(0, 8) : gitCommit;

  /// The version shown to people; desktop builds are still in beta.
  static String get displayVersion => versionLabel();

  @visibleForTesting
  static String versionLabel({bool debug = kDebugMode, bool? desktop}) {
    if (debug) return 'Internal';
    return desktop ?? isDesktopPlatform ? '$version (beta)' : version;
  }

  static const String appName = 'SpotiFLAC';
  static const String websiteUrl = 'https://spotiflac.com';
  static const String license = 'LGPL-3.0-only';
  static const String copyright = '© 2026 Zarz Eleutherius';

  static const String mobileAuthor = 'spotiflac-app';

  static const String githubRepo = String.fromEnvironment(
    'SPOTIFLAC_GITHUB_REPO',
    defaultValue: 'spotiflac-app/spotiflac',
  );
  static const String githubUrl = 'https://github.com/$githubRepo';

  /// All platform packages are published alongside the source.
  static const String desktopGithubRepo = String.fromEnvironment(
    'SPOTIFLAC_DESKTOP_GITHUB_REPO',
    defaultValue: 'spotiflac-app/spotiflac',
  );
  static const String remoteConfigApiUrl = String.fromEnvironment(
    'SPOTIFLAC_CONFIG_URL',
    defaultValue: 'https://raw.githubusercontent.com/spotiflac-app/spotiflac/main/config/app.json',
  );

  /// Enable only after registering and configuring your own Discord application.
  static const bool discordEnabled = bool.fromEnvironment(
    'SPOTIFLAC_DISCORD_ENABLED',
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spotiflac/utils/desktop_platform.dart';

const String kThemeModeKey = 'theme_mode';
const String kUseDynamicColorKey = 'use_dynamic_color';
const String kSeedColorKey = 'seed_color';
const String kUseAmoledKey = 'use_amoled';
const String kThemeStyleKey = 'theme_style';
const String kSpotiFLACAccentKey = 'spotiflac_accent';
const String kUseSystemFontKey = 'use_system_font';
const String kCustomFontIdKey = 'custom_font_id';
const String kCustomFontNameKey = 'custom_font_name';
const String kLyricsTextScaleKey = 'lyrics_text_scale';

double normalizeLyricsTextScale(num? value) =>
    value != null && value.isFinite ? value.toDouble().clamp(0.8, 1.4) : 1.0;
const String kSpotiFLACGlassClarityKey = 'spotiflac_glass_clarity';
const String kSpotiFLACGlassOutlinesKey = 'spotiflac_glass_outlines';
const double kDefaultSpotiFLACGlassClarity = 0.75;

double normalizeSpotiFLACGlassClarity(num? value) =>
    value != null && value.isFinite
    ? value.toDouble().clamp(0.0, 1.0)
    : kDefaultSpotiFLACGlassClarity;

enum AppThemeStyle { material, spotiflac }

enum SpotiFLACAccent { red, orange, green, teal, blue, purple, pink }

SpotiFLACAccent spotiflacAccentFromString(String? value) =>
    SpotiFLACAccent.values.firstWhere(
      (accent) => accent.name == value,
      orElse: () => SpotiFLACAccent.red,
    );

/// Style used until the person picks one: SpotiFLAC on macOS, Material on
/// Windows, Linux and mobile.
AppThemeStyle defaultAppThemeStyle() =>
    isDesktopPlatform && defaultTargetPlatform == TargetPlatform.macOS
    ? AppThemeStyle.spotiflac
    : AppThemeStyle.material;

AppThemeStyle themeStyleFromString(String? value) => AppThemeStyle.values
    .firstWhere((style) => style.name == value, orElse: defaultAppThemeStyle);

/// Default Spotify green color for fallback
const int kDefaultSeedColor = 0xFF1DB954;

class ThemeSettings {
  final ThemeMode themeMode;
  final bool useDynamicColor;
  final int seedColorValue;
  final bool useAmoled;
  final AppThemeStyle style;
  final SpotiFLACAccent spotiflacAccent;
  final bool useSystemFont;
  final String customFontId;
  final String customFontName;
  final double lyricsTextScale;
  final double spotiflacGlassClarity;
  final bool spotiflacGlassOutlines;

  const ThemeSettings({
    this.themeMode = ThemeMode.system,
    this.useDynamicColor = true,
    this.seedColorValue = kDefaultSeedColor,
    this.useAmoled = false,
    this.style = AppThemeStyle.material,
    this.spotiflacAccent = SpotiFLACAccent.red,
    this.useSystemFont = false,
    this.customFontId = '',
    this.customFontName = '',
    this.lyricsTextScale = 1,
    this.spotiflacGlassClarity = kDefaultSpotiFLACGlassClarity,
    this.spotiflacGlassOutlines = true,
  });

  Color get seedColor => Color(seedColorValue);

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    bool? useDynamicColor,
    int? seedColorValue,
    bool? useAmoled,
    AppThemeStyle? style,
    SpotiFLACAccent? spotiflacAccent,
    bool? useSystemFont,
    String? customFontId,
    String? customFontName,
    double? lyricsTextScale,
    double? spotiflacGlassClarity,
    bool? spotiflacGlassOutlines,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      useDynamicColor: useDynamicColor ?? this.useDynamicColor,
      seedColorValue: seedColorValue ?? this.seedColorValue,
      useAmoled: useAmoled ?? this.useAmoled,
      style: style ?? this.style,
      spotiflacAccent: spotiflacAccent ?? this.spotiflacAccent,
      useSystemFont: useSystemFont ?? this.useSystemFont,
      customFontId: customFontId ?? this.customFontId,
      customFontName: customFontName ?? this.customFontName,
      lyricsTextScale: normalizeLyricsTextScale(
        lyricsTextScale ?? this.lyricsTextScale,
      ),
      spotiflacGlassClarity: normalizeSpotiFLACGlassClarity(
        spotiflacGlassClarity ?? this.spotiflacGlassClarity,
      ),
      spotiflacGlassOutlines:
          spotiflacGlassOutlines ?? this.spotiflacGlassOutlines,
    );
  }

  Map<String, dynamic> toJson() => {
    kThemeModeKey: themeMode.name,
    kUseDynamicColorKey: useDynamicColor,
    kSeedColorKey: seedColorValue,
    kUseAmoledKey: useAmoled,
    kThemeStyleKey: style.name,
    kSpotiFLACAccentKey: spotiflacAccent.name,
    kUseSystemFontKey: useSystemFont,
    kCustomFontIdKey: customFontId,
    kCustomFontNameKey: customFontName,
    kLyricsTextScaleKey: lyricsTextScale,
    kSpotiFLACGlassClarityKey: spotiflacGlassClarity,
    kSpotiFLACGlassOutlinesKey: spotiflacGlassOutlines,
  };

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: themeModeFromString(json[kThemeModeKey] as String?),
      useDynamicColor: json[kUseDynamicColorKey] as bool? ?? true,
      seedColorValue: json[kSeedColorKey] as int? ?? kDefaultSeedColor,
      useAmoled: json[kUseAmoledKey] as bool? ?? false,
      style: themeStyleFromString(json[kThemeStyleKey] as String?),
      spotiflacAccent: spotiflacAccentFromString(
        json[kSpotiFLACAccentKey] as String?,
      ),
      useSystemFont: json[kUseSystemFontKey] as bool? ?? false,
      customFontId: json[kCustomFontIdKey] as String? ?? '',
      customFontName: json[kCustomFontNameKey] as String? ?? '',
      lyricsTextScale: normalizeLyricsTextScale(
        json[kLyricsTextScaleKey] as num?,
      ),
      spotiflacGlassClarity: normalizeSpotiFLACGlassClarity(
        json[kSpotiFLACGlassClarityKey] as num?,
      ),
      spotiflacGlassOutlines: json[kSpotiFLACGlassOutlinesKey] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeSettings &&
        other.themeMode == themeMode &&
        other.useDynamicColor == useDynamicColor &&
        other.seedColorValue == seedColorValue &&
        other.useAmoled == useAmoled &&
        other.style == style &&
        other.spotiflacAccent == spotiflacAccent &&
        other.useSystemFont == useSystemFont &&
        other.customFontId == customFontId &&
        other.customFontName == customFontName &&
        other.lyricsTextScale == lyricsTextScale &&
        other.spotiflacGlassClarity == spotiflacGlassClarity &&
        other.spotiflacGlassOutlines == spotiflacGlassOutlines;
  }

  @override
  int get hashCode =>
      themeMode.hashCode ^
      useDynamicColor.hashCode ^
      seedColorValue.hashCode ^
      useAmoled.hashCode ^
      style.hashCode ^
      spotiflacAccent.hashCode ^
      useSystemFont.hashCode ^
      customFontId.hashCode ^
      customFontName.hashCode ^
      lyricsTextScale.hashCode ^
      spotiflacGlassClarity.hashCode ^
      spotiflacGlassOutlines.hashCode;
}

ThemeMode themeModeFromString(String? value) {
  if (value == null) return ThemeMode.system;
  return ThemeMode.values.firstWhere(
    (e) => e.name == value,
    orElse: () => ThemeMode.system,
  );
}

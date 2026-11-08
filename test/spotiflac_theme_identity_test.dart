import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac/models/theme_settings.dart';
import 'package:spotiflac/providers/theme_provider.dart';
import 'package:spotiflac/theme/dynamic_color_wrapper.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';

class _ThemeReader extends StatelessWidget {
  const _ThemeReader(this.builds);

  final List<ThemeData> builds;

  @override
  Widget build(BuildContext context) {
    builds.add(Theme.of(context));
    return const SizedBox();
  }
}

void main() {
  test('SpotiFLAC preferences compare by value', () {
    const a = SpotiFLACTheme(
      chromeSurface: Color(0xff336699),
      accent: SpotiFLACAccent.blue,
      useSystemFont: true,
      fontFamily: 'Custom',
      glassClarity: 0.4,
      glassOutlines: false,
    );
    final b = a.copyWith();
    expect(b, a);
    expect(b.hashCode, a.hashCode);
    expect(a.copyWith(glassClarity: 0.5), isNot(a));
    expect(a.copyWith(accent: SpotiFLACAccent.red), isNot(a));
    expect(a.lerp(b, 0.5), a);
  });

  test('custom glass preferences reuse the same theme', () {
    for (final brightness in Brightness.values) {
      ThemeData build() => SpotiFLACTheme.build(
        brightness,
        accent: SpotiFLACAccent.teal,
        glassClarity: 0.4,
        glassOutlines: false,
      );
      final first = build();
      expect(identical(build(), first), isTrue);
      final preferences = first.extension<SpotiFLACTheme>()!;
      expect(preferences.glassClarity, 0.4);
      expect(preferences.glassOutlines, isFalse);
      expect(
        SpotiFLACTheme.build(
          brightness,
          accent: SpotiFLACAccent.teal,
          glassClarity: 1,
        ).extension<SpotiFLACTheme>()!.glassClarity,
        1,
      );
    }
  });

  test('artwork chrome only changes the chrome-derived roles', () {
    for (final brightness in Brightness.values) {
      for (final color in const [
        Color(0xff000000),
        Color(0xffffffff),
        Color(0xff7a1f3d),
        Color(0x80204060),
      ]) {
        final base = SpotiFLACTheme.build(
          brightness,
          accent: SpotiFLACAccent.green,
        );
        final chrome = SpotiFLACTheme.build(
          brightness,
          accent: SpotiFLACAccent.green,
          chromeSurface: color,
        );
        final high = Color.lerp(color, Colors.black, 0.16);
        expect(chrome.colorScheme.surfaceContainerHigh, high);
        expect(chrome.snackBarTheme.backgroundColor, high);
        expect(chrome.buttonTheme.colorScheme, chrome.colorScheme);
        expect(chrome.extension<SpotiFLACTheme>()!.chromeSurface, color);
        expect(
          chrome.copyWith(
            colorScheme: base.colorScheme,
            snackBarTheme: base.snackBarTheme,
            buttonTheme: base.buttonTheme,
            extensions: base.extensions.values,
          ),
          base,
        );
        expect(
          identical(
            SpotiFLACTheme.build(
              brightness,
              accent: SpotiFLACAccent.green,
              chromeSurface: color,
            ),
            chrome,
          ),
          isTrue,
        );
      }
    }
  });

  testWidgets('settings theme does not notify readers when rebuilt', (
    tester,
  ) async {
    final builds = <ThemeData>[];
    late StateSetter rebuild;
    final reader = _ThemeReader(builds);
    await tester.pumpWidget(
      MaterialApp(
        theme: SpotiFLACTheme.build(Brightness.light),
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return SpotiFLACSettingsTheme(child: reader);
          },
        ),
      ),
    );
    expect(builds, hasLength(1));
    rebuild(() {});
    await tester.pump();
    expect(builds, hasLength(1));
    expect(builds.single.scaffoldBackgroundColor, const Color(0xfff2f2f7));
  });

  testWidgets('only theme settings rebuild the app theme', (tester) async {
    SharedPreferences.setMockInitialValues({
      kThemeStyleKey: AppThemeStyle.spotiflac.name,
      kThemeModeKey: ThemeMode.light.name,
      kSpotiFLACGlassClarityKey: 0.4,
      kSpotiFLACGlassOutlinesKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        initialThemeSettingsProvider.overrideWithValue(
          loadBootstrapThemeSettings(prefs),
        ),
      ],
    );
    addTearDown(container.dispose);
    final themes = <ThemeData>[];
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: DynamicColorWrapper(
          builder: (light, dark, mode) {
            themes.add(light);
            return MaterialApp(
              theme: light,
              darkTheme: dark,
              themeMode: mode,
              home: const SizedBox(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(themes.last.extension<SpotiFLACTheme>()!.glassClarity, 0.4);
    final initialBuilds = themes.length;
    final notifier = container.read(themeProvider.notifier);

    await notifier.setLyricsTextScale(1.2, persist: false);
    await tester.pumpAndSettle();
    expect(container.read(themeProvider).lyricsTextScale, 1.2);
    expect(themes, hasLength(initialBuilds));

    await notifier.setSpotiFLACGlassClarity(0.6, persist: false);
    await tester.pumpAndSettle();
    expect(themes, hasLength(initialBuilds + 1));
    expect(themes.last.extension<SpotiFLACTheme>()!.glassClarity, 0.6);
  });
}

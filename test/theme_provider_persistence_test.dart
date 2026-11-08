import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac/models/theme_settings.dart';
import 'package:spotiflac/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stored red moves to blue once, and red picked later stays', () async {
    SharedPreferences.setMockInitialValues({kSpotiFLACAccentKey: 'red'});
    final prefs = await SharedPreferences.getInstance();
    expect(
      loadBootstrapThemeSettings(prefs).spotiflacAccent,
      SpotiFLACAccent.blue,
    );
    expect(prefs.getString(kSpotiFLACAccentKey), 'blue');

    await prefs.setString(kSpotiFLACAccentKey, 'red');
    expect(
      loadBootstrapThemeSettings(prefs).spotiflacAccent,
      SpotiFLACAccent.red,
    );
    expect(prefs.getString(kSpotiFLACAccentKey), 'red');
  });

  test('the move leaves any other accent alone', () async {
    SharedPreferences.setMockInitialValues({kSpotiFLACAccentKey: 'pink'});
    final prefs = await SharedPreferences.getInstance();
    expect(
      loadBootstrapThemeSettings(prefs).spotiflacAccent,
      SpotiFLACAccent.pink,
    );
    expect(prefs.getString(kSpotiFLACAccentKey), 'pink');
    expect(prefs.getBool(kSpotiFLACAccentMovedToBlueKey), isTrue);
  });

  test(
    'early theme edits preserve untouched saved settings and await saving',
    () async {
      SharedPreferences.setMockInitialValues({
        kThemeModeKey: 'dark',
        kThemeStyleKey: 'spotiflac',
        kSeedColorKey: 0xff123456,
        kUseDynamicColorKey: false,
        kUseAmoledKey: true,
        kUseSystemFontKey: true,
        kSpotiFLACAccentKey: 'blue',
        kSpotiFLACGlassClarityKey: 0.2,
      });
      final prefs = await SharedPreferences.getInstance();
      final releaseLoad = Completer<SharedPreferences>();
      final container = ProviderContainer(
        overrides: [
          themeProvider.overrideWith(
            () => ThemeNotifier(preferences: releaseLoad.future),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(themeProvider.notifier);
      // An explicit edit equal to the bootstrap default still owns this field.
      final savingMode = notifier.setThemeMode(ThemeMode.system);
      final savingAccent = notifier.setSpotiFLACAccent(SpotiFLACAccent.red);
      await notifier.setSpotiFLACGlassClarity(0.8, persist: false);
      var saved = false;
      unawaited(savingAccent.then((_) => saved = true));
      await Future<void>.delayed(Duration.zero);
      expect(saved, isFalse);
      expect(container.read(themeProvider).spotiflacGlassClarity, 0.8);
      expect(prefs.getString(kThemeModeKey), 'dark');

      releaseLoad.complete(prefs);
      await Future.wait([savingMode, savingAccent]);
      final state = container.read(themeProvider);
      expect(state.themeMode, ThemeMode.system);
      expect(state.spotiflacAccent, SpotiFLACAccent.red);
      expect(state.spotiflacGlassClarity, 0.8);
      expect(state.style, AppThemeStyle.spotiflac);
      expect(state.seedColorValue, 0xff123456);
      expect(state.useDynamicColor, isFalse);
      expect(state.useAmoled, isTrue);
      expect(state.useSystemFont, isTrue);
      expect(loadBootstrapThemeSettings(prefs), state);
    },
  );

  test('early preview remains immediate without writing preferences', () async {
    SharedPreferences.setMockInitialValues({
      kSpotiFLACGlassClarityKey: 0.2,
      kSpotiFLACAccentKey: 'blue',
    });
    final prefs = await SharedPreferences.getInstance();
    final releaseLoad = Completer<SharedPreferences>();
    final loaded = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        themeProvider.overrideWith(
          () => ThemeNotifier(preferences: releaseLoad.future),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(themeProvider, (_, next) {
      if (next.spotiflacAccent == SpotiFLACAccent.blue) loaded.complete();
    });
    await container
        .read(themeProvider.notifier)
        .setSpotiFLACGlassClarity(0.8, persist: false);
    expect(container.read(themeProvider).spotiflacGlassClarity, 0.8);
    releaseLoad.complete(prefs);
    await loaded.future;
    expect(container.read(themeProvider).spotiflacGlassClarity, 0.8);
    expect(prefs.getDouble(kSpotiFLACGlassClarityKey), 0.2);
  });

  test(
    'failed preference loading keeps early edits without leaking errors',
    () async {
      final releaseLoad = Completer<SharedPreferences>();
      final container = ProviderContainer(
        overrides: [
          themeProvider.overrideWith(
            () => ThemeNotifier(preferences: releaseLoad.future),
          ),
        ],
      );
      addTearDown(container.dispose);
      final saving = container.read(themeProvider.notifier).setUseAmoled(true);
      releaseLoad.completeError(StateError('theme_load_failed'));
      await saving;
      expect(container.read(themeProvider).useAmoled, isTrue);
    },
  );

  test(
    'disposed theme does not read state or save after delayed loading',
    () async {
      SharedPreferences.setMockInitialValues({kUseAmoledKey: false});
      final prefs = await SharedPreferences.getInstance();
      final releaseLoad = Completer<SharedPreferences>();
      final container = ProviderContainer(
        overrides: [
          themeProvider.overrideWith(
            () => ThemeNotifier(preferences: releaseLoad.future),
          ),
        ],
      );
      final saving = container.read(themeProvider.notifier).setUseAmoled(true);
      container.dispose();
      releaseLoad.complete(prefs);
      await saving;
      expect(prefs.getBool(kUseAmoledKey), isFalse);
    },
  );
}

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac/l10n/l10n.dart';
import 'package:spotiflac/models/settings.dart';
import 'package:spotiflac/providers/settings_provider.dart';
import 'package:spotiflac/screens/settings/files_settings_page.dart';
import 'package:spotiflac/utils/desktop_platform.dart';

import 'support/fixed_settings.dart';

/// Holds the folder dialog open until the test completes [result].
class _PendingDirectoryPicker extends FilePickerPlatform {
  final result = Completer<String?>();
  int calls = 0;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory,
    AndroidOptions androidOptions = const AndroidOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) {
    calls++;
    return result.future;
  }
}

void main() {
  late Directory root;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    root = Directory.systemTemp.createTempSync('download_folder_picker_');
  });

  tearDown(() {
    debugDesktopPlatformOverride = null;
    debugDefaultTargetPlatformOverride = null;
    root.deleteSync(recursive: true);
  });

  testWidgets(
    'desktop download folder is saved when the page closes during the picker',
    (tester) async {
      debugDesktopPlatformOverride = true;
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final current = Directory(p.join(root.path, 'Current'))..createSync();
      final selected = p.join(root.path, 'Selected');
      final picker = _PendingDirectoryPicker();
      final originalPicker = FilePickerPlatform.instance;
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = originalPicker);
      final container = ProviderContainer(
        overrides: [
          settingsProvider.overrideWith(
            () => FixedSettingsNotifier(
              AppSettings(storageMode: 'app', downloadDirectory: current.path),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      Widget app(Widget home) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

      await tester.pumpWidget(app(const FilesSettingsPage()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(current.path));
      for (var frame = 0; picker.calls == 0 && frame < 30; frame++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(picker.calls, 1);

      // The native dialog can outlive the page that opened it.
      await tester.pumpWidget(app(const SizedBox()));
      expect(find.byType(FilesSettingsPage), findsNothing);
      picker.result.complete(selected);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final settings = container.read(settingsProvider);
      expect(settings.downloadDirectory, selected);
      expect(settings.storageMode, 'app');
      debugDefaultTargetPlatformOverride = null;
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotiflac/l10n/l10n.dart';
import 'package:spotiflac/providers/settings_provider.dart';
import 'package:spotiflac/screens/settings/files_settings_page.dart';
import 'package:spotiflac/theme/app_theme.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';
import 'package:spotiflac/utils/desktop_platform.dart';
import 'package:spotiflac/widgets/settings_group.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixed_settings.dart';

void main() {
  for (final spotiflac in [false, true]) {
    testWidgets(
      'Files scrolls its last row above floating chrome ($spotiflac)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        debugDesktopPlatformOverride = true;
        addTearDown(() => debugDesktopPlatformOverride = null);
        tester.view.physicalSize = const Size(1200, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const inset = 88.0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              settingsProvider.overrideWith(FixedSettingsNotifier.new),
            ],
            child: MaterialApp(
              theme: spotiflac
                  ? SpotiFLACTheme.build(Brightness.dark)
                  : AppTheme.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(padding: const EdgeInsets.only(bottom: inset)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const SpotiFLACSettingsTheme(child: FilesSettingsPage()),
                      const Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: inset,
                        child: ColoredBox(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final filters = find.byWidgetPredicate(
          (widget) =>
              widget is SettingsItem && widget.title == 'Artist Name Filters',
        );
        expect(
          tester.getBottomRight(filters).dy,
          lessThanOrEqualTo(700 - inset),
        );
        await tester.tap(filters);
        await tester.pumpAndSettle();
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
        final contributing = find.byWidgetPredicate(
          (widget) =>
              widget is SettingsSwitchItem &&
              widget.title == 'Filter Contributing Artists',
        );
        expect(
          tester.getBottomRight(contributing).dy,
          lessThanOrEqualTo(700 - inset),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:spotiflac/screens/main_shell.dart';
import 'package:spotiflac/services/shell_navigation_service.dart';

void main() {
  int? switched(
    int index, {
    required bool fromSpotiFLAC,
    required bool showStore,
    bool desktop = true,
  }) => shellIndexOfTab(
    shellTabAt(index, spotiflac: fromSpotiFLAC, showStore: showStore),
    spotiflac: !fromSpotiFLAC,
    showStore: showStore,
    desktop: desktop,
  );

  for (final showStore in [false, true]) {
    test(
      'switching styles keeps the tab, not the index (store: $showStore)',
      () {
        final materialSettings = showStore ? 3 : 2;
        final spotiflacSearch = showStore ? 3 : 2;
        final spotiflacSettings = showStore ? 4 : 3;

        // Material Settings stays Settings instead of becoming Search.
        expect(
          switched(materialSettings, fromSpotiFLAC: false, showStore: showStore),
          spotiflacSettings,
        );
        expect(
          switched(spotiflacSettings, fromSpotiFLAC: true, showStore: showStore),
          materialSettings,
        );
        // SpotiFLAC's Search lands on Material's Home, where Material searches.
        expect(
          switched(spotiflacSearch, fromSpotiFLAC: true, showStore: showStore),
          0,
        );
        for (final index in [0, 1, if (showStore) 2]) {
          expect(
            switched(index, fromSpotiFLAC: false, showStore: showStore),
            index,
          );
        }
        // SpotiFLAC phones have no Settings destination.
        expect(
          switched(
            materialSettings,
            fromSpotiFLAC: false,
            showStore: showStore,
            desktop: false,
          ),
          isNull,
        );
      },
    );
  }

  test('SpotiFLAC Search maps to its own tab', () {
    expect(shellTabAt(2, spotiflac: true, showStore: false), ShellTab.search);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotiflac/l10n/l10n.dart';
import 'package:spotiflac/screens/track_metadata_screen.dart';
import 'package:spotiflac/services/library_database.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';

void main() {
  for (final spotiflac in [false, true]) {
    for (final (width, twoColumns) in [(1400.0, true), (800.0, false)]) {
      testWidgets(
        'metadata cards at ${width.toInt()} wide use '
        '${twoColumns ? 'two columns' : 'one column'} (SpotiFLAC=$spotiflac)',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final item = LocalLibraryItem(
            id: '/music/track.flac',
            filePath: '/music/track.flac',
            trackName: 'Track',
            artistName: 'Artist',
            albumName: 'Album',
            scannedAt: DateTime(2026),
          );
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: spotiflac
                    ? SpotiFLACTheme.build(Brightness.dark)
                    : ThemeData.dark(useMaterial3: true),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: TrackMetadataScreen(localItem: item),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          // SpotiFLAC also names the page "Metadata" in its navigation bar.
          final metadata = tester.getTopLeft(find.text('Metadata').last);
          final lyrics = tester.getTopLeft(find.text('Lyrics').last);
          if (twoColumns) {
            expect(lyrics.dx, greaterThan(metadata.dx + 400));
            expect(lyrics.dy, moreOrLessEquals(metadata.dy, epsilon: 1));
          } else {
            expect(lyrics.dx, moreOrLessEquals(metadata.dx, epsilon: 1));
            expect(lyrics.dy, greaterThan(metadata.dy));
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}

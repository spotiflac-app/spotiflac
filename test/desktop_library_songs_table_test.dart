import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotiflac/l10n/l10n.dart';
import 'package:spotiflac/models/download_item.dart';
import 'package:spotiflac/models/settings.dart';
import 'package:spotiflac/models/track.dart';
import 'package:spotiflac/providers/download_queue_provider.dart';
import 'package:spotiflac/providers/library_collections_provider.dart';
import 'package:spotiflac/providers/local_library_provider.dart';
import 'package:spotiflac/providers/playback_provider.dart';
import 'package:spotiflac/providers/settings_provider.dart';
import 'package:spotiflac/screens/spotiflac_library_screen.dart';
import 'package:spotiflac/screens/queue_tab.dart';
import 'package:spotiflac/services/history_database.dart';
import 'package:spotiflac/services/library_database.dart';
import 'package:spotiflac/services/playable_media.dart';
import 'package:spotiflac/theme/app_theme.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';
import 'package:spotiflac/utils/desktop_platform.dart';
import 'package:spotiflac/widgets/desktop/track_table.dart';
import 'package:spotiflac/widgets/library_track_selection_bar.dart';
import 'package:spotiflac/widgets/spotiflac_context_menu.dart';
import 'package:spotiflac/widgets/track_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class _Settings extends SettingsNotifier {
  _Settings(this.viewMode, {this.filterMode = 'all'});

  final String viewMode;
  final String filterMode;

  // The Rewind banner animates for as long as it is shown; keep it off so
  // the page settles.
  @override
  AppSettings build() => AppSettings(
    defaultLibraryView: filterMode,
    historyFilterMode: filterMode,
    historyViewMode: viewMode,
    listeningStatisticsEnabled: false,
  );
}

/// Two downloaded songs. With a queue item present and the database page
/// empty, the Library renders this in-memory snapshot.
class _History extends DownloadHistoryNotifier {
  @override
  DownloadHistoryState build() => DownloadHistoryState(
    items: [
      for (final (index, name) in ['Bravo', 'Alpha'].indexed)
        DownloadHistoryItem(
          id: 'song-$index',
          trackName: name,
          artistName: 'Artist',
          albumName: 'Album $index',
          filePath: '/music/$name.flac',
          service: 'example-provider',
          downloadedAt: DateTime(2026, 1, 10 + index),
        ),
    ],
    totalCount: 2,
  );
}

class _Local extends LocalLibraryNotifier {
  @override
  LocalLibraryState build() => LocalLibraryState();
}

class _Collections extends LibraryCollectionsNotifier {
  _Collections({this.withPlaylistTracks = false});

  final bool withPlaylistTracks;

  @override
  LibraryCollectionsState build() => LibraryCollectionsState(
    isLoaded: true,
    playlists: [
      if (withPlaylistTracks)
        UserPlaylistCollection(
          id: 'playlist',
          name: 'Playlist',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          tracks: const [],
          tracksLoaded: false,
          trackKeys: {'example-provider:song-0', 'example-provider:song-1'},
        ),
    ],
  );
}

class _Queue extends DownloadQueueNotifier {
  @override
  DownloadQueueState build() => DownloadQueueState();
}

class _Playback extends PlaybackController {
  final started = <String>[];

  @override
  Future<void> playMediaQueue(
    Iterable<PlayableMedia> queue, {
    required int startIndex,
    required String externalPath,
  }) async {
    started.add(externalPath);
  }
}

/// The Library's database page keeps a loading indicator spinning, so this
/// settles with bounded pumps.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _rightClick(WidgetTester tester, Finder finder) async {
  final gesture = await tester.startGesture(
    tester.getCenter(finder),
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final previousFactory = databaseFactoryOrNull;
    databaseFactory = databaseFactorySqflitePlugin;
    addTearDown(() => databaseFactory = previousFactory);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(paths, (_) async => '/test/documents');
    addTearDown(() => messenger.setMockMethodCallHandler(paths, null));
    // An empty database: every page query returns no rows.
    const sqlite = MethodChannel('com.tekartik.sqflite');
    final versions = <int, int>{};
    messenger.setMockMethodCallHandler(sqlite, (call) async {
      final args = (call.arguments as Map?) ?? {};
      if (call.method == 'openDatabase') {
        final id = versions.length + 1;
        versions[id] = (args['path'] as String).endsWith('history.db')
            ? HistoryDatabase.schemaVersion
            : LibraryDatabase.schemaVersion;
        return {'id': id};
      }
      final sql = args['sql'] as String? ?? '';
      if (call.method == 'execute' && sql.contains('CREATE VIRTUAL TABLE')) {
        throw PlatformException(code: 'sqlite_error', message: 'no fts5');
      }
      if (call.method != 'query') return null;
      if (sql.toLowerCase().contains('pragma user_version')) {
        return {
          'columns': ['user_version'],
          'rows': [
            [versions[args['id']]],
          ],
        };
      }
      return {'columns': <String>[], 'rows': <List<Object?>>[]};
    });
    addTearDown(() => messenger.setMockMethodCallHandler(sqlite, null));
  });
  tearDown(() => debugDesktopPlatformOverride = null);

  Future<void> pumpLibrary(
    WidgetTester tester, {
    required bool desktop,
    bool spotiflac = false,
    String viewMode = 'list',
    String filterMode = 'all',
    bool withPlaylistTracks = false,
    bool root = false,
    PlaybackController? playback,
  }) async {
    debugDesktopPlatformOverride = desktop;
    tester.view.physicalSize = desktop
        ? const Size(1280, 900)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final queue = DownloadQueueLookup.fromItems([
      DownloadItem(
        id: 'completed',
        track: const Track(
          id: 'song',
          name: 'Song',
          artistName: 'Artist',
          albumName: 'Album',
          duration: 1000,
        ),
        service: 'example-provider',
        status: DownloadStatus.completed,
        createdAt: DateTime(2026),
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            () => _Settings(viewMode, filterMode: filterMode),
          ),
          downloadHistoryProvider.overrideWith(_History.new),
          localLibraryProvider.overrideWith(_Local.new),
          libraryCollectionsProvider.overrideWith(
            () => _Collections(withPlaylistTracks: withPlaylistTracks),
          ),
          downloadQueueProvider.overrideWith(_Queue.new),
          downloadQueueLookupProvider.overrideWithValue(queue),
          if (playback != null) playbackProvider.overrideWith(() => playback),
        ],
        child: MaterialApp(
          theme: spotiflac
              ? SpotiFLACTheme.build(Brightness.light)
              : AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // SpotiFLAC opens Songs as a section page from its Library root.
          home: Scaffold(
            body: QueueTab(
              librarySection: spotiflac && !root ? filterMode : null,
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
  }

  for (final spotiflac in [false, true]) {
    testWidgets(
      'desktop Songs list is the songs table (spotiflac: $spotiflac)',
      (tester) async {
        await pumpLibrary(tester, desktop: true, spotiflac: spotiflac);
        expect(find.byType(SliverTrackTable), findsOneWidget);
        expect(find.byType(TrackCard), findsNothing);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Bravo'), findsOneWidget);
        // No month sections: the table sorts through its header instead.
        expect(find.text('January 2026'), findsNothing);
        final l10n = AppLocalizations.of(tester.element(find.byType(QueueTab)));
        await tester.tap(find.text(l10n.editMetadataFieldTitle));
        await _settle(tester);
        final preferences = await SharedPreferences.getInstance();
        expect(loadBootstrapSettings(preferences).historySortMode, 'a-z');
      },
    );

    testWidgets('a right-click menu leaves the selection toolbar closed '
        '(spotiflac: $spotiflac)', (tester) async {
      final playback = _Playback();
      await pumpLibrary(
        tester,
        desktop: true,
        spotiflac: spotiflac,
        playback: playback,
      );
      final toolbar = find.byType(LibraryTrackSelectionBar);
      Finder menuRow(String label) => find.descendant(
        of: find.byType(spotiflac ? SpotiFLACContextMenu : MenuItemButton),
        matching: find.text(label),
      );

      // The menu acts on the song without opening the toolbar under it,
      // and closing the menu ends that selection.
      await _rightClick(tester, find.text('Alpha'));
      expect(menuRow('Play next'), findsOneWidget);
      expect(toolbar, findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(menuRow('Play next'), findsNothing);
      expect(toolbar, findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(toolbar, findsNothing);

      await _rightClick(tester, find.text('Alpha'));
      await tester.tap(menuRow('Play'));
      await _settle(tester);
      expect(playback.started, ['/music/Alpha.flac']);
      expect(toolbar, findsNothing);

      // A bulk action keeps the selection, so the toolbar returns.
      await _rightClick(tester, find.text('Bravo'));
      await tester.tap(menuRow('Delete 1 track'));
      await _settle(tester);
      expect(toolbar, findsOneWidget);
    });
  }

  testWidgets('desktop Songs grid keeps the cover grid', (tester) async {
    await pumpLibrary(tester, desktop: true, viewMode: 'grid');
    expect(find.byType(SliverTrackTable), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('phones keep the sectioned song cards', (tester) async {
    await pumpLibrary(tester, desktop: false);
    expect(find.byType(SliverTrackTable), findsNothing);
    expect(find.byType(TrackCard), findsNWidgets(2));
    expect(find.text('January 2026'), findsOneWidget);
  });

  for (final desktop in [false, true]) {
    for (final spotiflac in [false, true]) {
      for (final viewMode in spotiflac ? ['list'] : ['list', 'grid']) {
        for (final mode in ['all', 'singles']) {
          testWidgets(
            'playlist members remain visible '
            '(desktop: $desktop, spotiflac: $spotiflac, view: $viewMode, mode: $mode)',
            (tester) async {
              await pumpLibrary(
                tester,
                desktop: desktop,
                spotiflac: spotiflac,
                viewMode: viewMode,
                filterMode: mode,
                withPlaylistTracks: true,
              );
              expect(find.text('2 tracks'), findsWidgets);
              expect(find.text('Alpha'), findsOneWidget);
              expect(find.text('Bravo'), findsOneWidget);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  testWidgets(
    'switching from SpotiFLAC to Material keeps playlist songs visible',
    (tester) async {
      await pumpLibrary(
        tester,
        desktop: false,
        spotiflac: true,
        root: true,
        withPlaylistTracks: true,
      );
      expect(find.byType(SpotiFLACLibraryScreen), findsOneWidget);
      await pumpLibrary(
        tester,
        desktop: false,
        viewMode: 'grid',
        withPlaylistTracks: true,
      );
      expect(find.byType(SpotiFLACLibraryScreen), findsNothing);
      expect(find.text('2 tracks'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

import 'spotiflac_artwork_performance_test.dart' as artwork;
import 'spotiflac_lyrics_performance_test.dart' as lyrics;
import 'spotiflac_rendering_performance_test.dart' as rendering;
import 'spotiflac_screens_performance_test.dart' as screens;
import 'performance_probe.dart';

void main() {
  PerformanceTestBinding.ensureInitialized();
  rendering.main();
  screens.main();
  artwork.main();
  lyrics.main();
}

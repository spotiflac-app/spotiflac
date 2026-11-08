import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac/l10n/l10n.dart';
import 'package:spotiflac/models/track.dart';
import 'package:spotiflac/providers/library_collections_provider.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';
import 'package:spotiflac/utils/desktop_platform.dart';
import 'package:spotiflac/widgets/album_detail_header.dart';
import 'package:spotiflac/widgets/expressive_button_group.dart';

/// Love all, download all and add to playlist buttons of a track collection
/// header, laid out for desktop, SpotiFLAC or Material. All three are disabled
/// while [tracks] is empty.
class CollectionHeaderActions extends StatelessWidget {
  const CollectionHeaderActions({
    super.key,
    required this.tracks,
    required this.onLoveAll,
    required this.downloadIcon,
    required this.onDownloadAll,
    required this.addToPlaylistIcon,
    required this.onAddToPlaylist,
    this.tonalDownload = false,
  });

  final List<Track> tracks;
  final VoidCallback onLoveAll;

  /// The Material download glyph; SpotiFLAC uses its filled arrow.
  final IconData downloadIcon;
  final VoidCallback onDownloadAll;
  final bool tonalDownload;
  final IconData addToPlaylistIcon;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final enabled = tracks.isNotEmpty;
    final spotiflac = context.isSpotiFLAC;
    final love = Consumer(
      builder: (context, ref, _) {
        ref.watch(libraryCollectionsProvider.select((state) => state.loved));
        final collectionsState = ref.read(libraryCollectionsProvider);
        final allLoved =
            enabled && tracks.every((t) => collectionsState.isLoved(t));
        return HeaderCircleButton(
          icon: allLoved ? Icons.favorite : Icons.favorite_border,
          tonal: true,
          iconColor: allLoved ? Theme.of(context).colorScheme.error : null,
          tooltip: allLoved
              ? context.l10n.trackOptionRemoveFromLoved
              : context.l10n.tooltipLoveAll,
          onPressed: enabled ? onLoveAll : null,
        );
      },
    );
    final download = HeaderFilledButton(
      icon: spotiflac ? CupertinoIcons.arrow_down_circle_fill : downloadIcon,
      tonal: tonalDownload,
      label: spotiflac
          ? context.l10n.dialogDownload
          : context.l10n.downloadAllCount(tracks.length),
      onPressed: enabled ? onDownloadAll : null,
    );
    final addToPlaylist = HeaderCircleButton(
      icon: addToPlaylistIcon,
      tonal: true,
      tooltip: context.l10n.tooltipAddToPlaylist,
      onPressed: enabled ? onAddToPlaylist : null,
    );
    if (isDesktopPlatform) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [love, download, addToPlaylist],
      );
    }
    if (spotiflac) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          love,
          const SizedBox(width: 16),
          Flexible(child: SizedBox(width: 172, child: download)),
          const SizedBox(width: 16),
          addToPlaylist,
        ],
      );
    }
    return ExpressiveButtonGroup(
      flexible: const {1},
      children: [love, download, addToPlaylist],
    );
  }
}

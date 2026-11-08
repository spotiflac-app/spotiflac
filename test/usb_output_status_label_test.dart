import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotiflac/l10n/app_localizations.dart';
import 'package:spotiflac/services/music_playback_deck.dart';
import 'package:spotiflac/utils/usb_output_status_label.dart';

void main() {
  for (final language in ['en', 'id']) {
    test('USB states remain distinct in $language', () async {
      final l10n = await AppLocalizations.delegate.load(Locale(language));
      final labels = [
        for (final reason in [
          'idle',
          'preparing',
          'ready',
          'cancelled',
          'unsupported',
        ])
          usbOutputStatusLabel(l10n, UsbAudioStatus(reason: reason)),
      ];
      expect(labels.toSet(), hasLength(5));
      expect(
        usbOutputStatusLabel(l10n, const UsbAudioStatus(reason: 'active')),
        l10n.usbBitPerfectFallback,
      );
    });
  }
}

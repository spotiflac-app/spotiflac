import 'package:flutter/material.dart';
import 'package:spotiflac/l10n/l10n.dart';
import 'package:spotiflac/services/cast_output.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';
import 'package:spotiflac/widgets/app_icon.dart';
import 'package:spotiflac/widgets/app_icon_button.dart';
import 'package:spotiflac/widgets/cast_device_picker.dart';

/// Opens the Google Cast receivers on the network. The glyph shows an active
/// session, whose name the tooltip gives.
class DesktopCastButton extends StatelessWidget {
  const DesktopCastButton({super.key, this.output});

  /// The Cast session; [CastOutput.instance] when null.
  final CastOutput? output;

  @override
  Widget build(BuildContext context) {
    final output = this.output ?? CastOutput.instance;
    return ListenableBuilder(
      listenable: output,
      builder: (context, _) {
        final spotiflac = context.isSpotiFLAC;
        final colorScheme = Theme.of(context).colorScheme;
        return AppIconButton(
          key: const ValueKey('desktop-cast-button'),
          tooltip: output.connected
              ? output.deviceName ?? context.l10n.audioOutputCast
              : context.l10n.audioOutputCast,
          color: output.connected
              ? colorScheme.primary
              : spotiflac
              ? colorScheme.onSurface
              : null,
          icon: AppIcon(
            output.connected ? Icons.cast_connected : Icons.cast,
            size: spotiflac ? 18 : 24,
          ),
          onPressed: () => showCastDevicePicker(context, output: output),
        );
      },
    );
  }
}

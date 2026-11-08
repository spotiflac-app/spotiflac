import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac/controllers/spotiflac_glass_warmup.dart';
import 'package:spotiflac/providers/runtime_profile_provider.dart';
import 'package:spotiflac/theme/spotiflac_theme.dart';

/// Starts the one-time preparation when the full glass theme is enabled,
/// including switching to SpotiFLAC or enabling blur after the app has started.
class SpotiFLACGlassPreparation extends ConsumerWidget {
  const SpotiFLACGlassPreparation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.isSpotiFLAC &&
        ref.watch(spotiflacGlassLevelProvider) == SpotiFLACGlassLevel.liquid &&
        SpotiFLACTheme.glassClarityOf(context) > 0.2 &&
        !ref.watch(
          spotiflacGlassContrastBlockedProvider(
            MediaQuery.highContrastOf(context),
          ),
        )) {
      unawaited(SpotiFLACGlassWarmup.prepare(View.of(context)));
    }
    return child;
  }
}

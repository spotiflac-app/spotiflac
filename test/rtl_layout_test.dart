import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotiflac/theme/spotiflac_icons.dart';

void main() {
  test('SpotiFLAC directional icons mirror in right-to-left layouts', () {
    for (final icon in [
      spotiflacIconFor(Icons.arrow_back),
      spotiflacIconFor(Icons.chevron_left),
      spotiflacArrowForward,
      CupertinoIcons.back,
      CupertinoIcons.forward,
      CupertinoIcons.right_chevron,
    ]) {
      expect(icon.matchTextDirection, isTrue, reason: '$icon');
    }
    // The mirrored glyphs are the same shapes as the SF-style names.
    expect(
      CupertinoIcons.back.codePoint,
      CupertinoIcons.chevron_back.codePoint,
    );
    expect(
      CupertinoIcons.forward.codePoint,
      CupertinoIcons.chevron_forward.codePoint,
    );
    expect(
      spotiflacArrowForward.codePoint,
      CupertinoIcons.arrow_right.codePoint,
    );
  });
}

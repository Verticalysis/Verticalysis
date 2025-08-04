// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/widgets.dart';

extension type FadeGFX._(ValueNotifier<int> bitfield) {
  FadeGFX() : bitfield = ValueNotifier(0);

  bool get fadein => bitfield.value & 1 == 1;
  bool get fadeout => bitfield.value & 2 == 2;

  set fadein(bool enable) => bitfield.value = (bitfield.value & ~1) | (enable ? 1 : 0);
  set fadeout(bool enable) => bitfield.value = (bitfield.value & ~2) | (enable ? 2 : 0);
}

final class FadedSliver extends StatelessWidget {
  const FadedSliver({
    super.key,
    required this.child,
    required this.scrollController,
    this.topFadeEnd = 0.2,
    this.bottomFadeStart = 0.8,
  }): assert(
    topFadeEnd <= 1.0,
    'Top fade stops must satisfy 0.0 < topFadeEnd <= 1.0'
  ), assert(
    bottomFadeStart >= 0.0,
    'Bottom fade stops must satisfy 0.0 <= bottomFadeStart < 1.0'
  ), assert(
    topFadeEnd <= bottomFadeStart,
    'Top fade end must be less than or equal to bottom fade start'
  );

  final Widget child;
  final ScrollController scrollController;
  final double topFadeEnd;
  final double bottomFadeStart;

  void _updateFade(FadeGFX fade) {
    if (scrollController.hasClients) {
      final offset = scrollController.offset;
      final maxExtent = scrollController.position.maxScrollExtent;

      fade.fadein = offset > 0;
      // Show bottom fade only if not at the bottom (offset < maxScrollExtent)
      fade.fadeout = offset < maxExtent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = FadeGFX();
    scrollController.addListener(() => _updateFade(fade));
    // Initial check for fade visibility
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFade(fade));

    return ValueListenableBuilder<int>(
      valueListenable: fade.bitfield,
      builder: (context, _, __) => ShaderMask(
        shaderCallback: (Rect rect) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            fade.fadein ? const Color(0xFF000000) : const Color(0x00000000),
            const Color(0x00000000),
            const Color(0x00000000),
            fade.fadeout ? const Color(0xFF000000) : const Color(0x00000000),
          ],
          stops: [ .0, topFadeEnd, bottomFadeStart, 1.0 ],
        ).createShader(rect),
        blendMode: BlendMode.dstOut,
        child: child,
      ),
    );
  }
}

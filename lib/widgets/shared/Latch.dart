// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/widgets.dart';

import 'Hoverable.dart';

/// A bistable button with a colored underline as indicator
Widget Latch(String label, Color indicatorColor, {
  VoidCallback? onClick,
  Color hoveringColor = const Color(0x00000000),
  double vMargin = 0.9,
  double hMargin = 0.9,
  double hPadding = 9,
  double vPadding = 0,
  required TextStyle textStyle,
}) => GestureDetector(
  onTap: onClick,
  child: HoverEffect(
    margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: vMargin),
    padding: EdgeInsets.fromLTRB(hPadding, vPadding + 9, hPadding, vPadding),
    hoveringCosmetic: BoxDecoration(
      color: hoveringColor,
    ),
    child: Text(label, style: TextStyle(
      fontSize: textStyle.fontSize,
      color: Color(0x00000000),
      decoration: TextDecoration.underline,
      decorationColor: indicatorColor,
      decorationStyle: TextDecorationStyle.solid,
      decorationThickness: 3,
      shadows: [Shadow(
        color: textStyle.color!,
        offset: const Offset(0, -6)
      )],
    ))
  )
);

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math';

import 'package:flutter/widgets.dart';

extension AsColor on int {
  Color get asColor => Color.fromARGB(
    (this >> 24) & 0xFF,
    (this >> 16) & 0xFF,
    (this >> 8) & 0xFF,
    this & 0xFF
  );
}

extension AsProperty on Map {
  TextStyle get asTextStyle => TextStyle(
    color: (this["color"] as int).asColor,
    backgroundColor: (this["backgroundColor"] as int).asColor,
    fontSize: this["fontSize"],
    letterSpacing: this["letterSpacing"],
    wordSpacing: this["wordSpacing"],
    fontFamily: this["fontFamily"],
  );
}

extension type const AsymptoticPalette(int color) {
  static const scaling = 6;

  int operator[] (double i) {
    int a = (color >> 24) & 0xFF;
    int r = (color >> 16) & 0xFF;
    int g = (color >> 8) & 0xFF;
    int b = color & 0xFF;

    // Logarithmic darkening factor
    // Using ln(1 + i) creates asymptotic behavior
    double factor = i > 0 ? (1.0 / (1.0 + i)) : 1.0;

    // Apply logarithmic scaling for smoother approach to black
    double logFactor = factor > 0 ? (-log(factor) / scaling).clamp(0.0, 1.0) : 0.0;

    // Interpolate between original color and black
    r = (r * (1.0 - logFactor)).round();
    g = (g * (1.0 - logFactor)).round();
    b = (b * (1.0 - logFactor)).round();

    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}

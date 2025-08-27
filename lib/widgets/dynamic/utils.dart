// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

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

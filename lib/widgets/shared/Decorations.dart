// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/widgets.dart';

extension type Vdivider._(Container container) implements Widget {
  Vdivider({
    required Color color,
    double width = 0.6,
    double height = 21
  }): container = Container(
    height: height,
    width: 1,
    color: color,
  );
}

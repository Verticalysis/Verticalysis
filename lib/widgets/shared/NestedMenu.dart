// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';

import '../Style.dart';

extension type NestedMenu(List<Widget> items) {
  Widget withIcon(Widget icon, {
    EdgeInsetsGeometry? padding,
    MouseCursor? cursor,
    VisualDensity? visualDensity,
    double iconSize = 15,
    Size? fixedSize = const Size.square(13.5),
    String? tooltip,
  }) => MenuAnchor(
    menuChildren: items,
    builder: (context, ctrl, _) => IconButton(
      padding: padding,
      tooltip: tooltip,
      onPressed: () => ctrl.isOpen ? ctrl.close() : ctrl.open(),
      visualDensity: visualDensity,
      mouseCursor: cursor,
      iconSize: iconSize,
      icon: icon,
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: rectBorder),
        fixedSize: fixedSize
      )
    ),
  );
}

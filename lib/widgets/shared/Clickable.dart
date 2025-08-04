// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

extension type Clickable._(MouseRegion wrapper) implements Widget {
  Clickable(Widget child, {
    VoidCallback? onClick,
    PointerEnterEventListener? onMouseIn,
    PointerExitEventListener? onMouseOut
  }): wrapper = MouseRegion(
    onEnter: onMouseIn,
    onExit: onMouseOut,
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onClick,
      child: child,
    ),
  );
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/widgets.dart';

extension type Hoverable._(ValueNotifier<bool> _hovering) {
  Hoverable(): _hovering = ValueNotifier(false);

  Widget build(ValueWidgetBuilder<bool> builder, {
    MouseCursor cursor = SystemMouseCursors.click,
  }) => MouseRegion(
    cursor: cursor,
    onHover: (_) => _hovering.value = true,
    onExit: (_) => _hovering.value = false,
    child: ValueListenableBuilder(
      valueListenable: _hovering,
      builder: builder
    )
  );
}

/// A container switches its decoration when being hovered
final class HoverEffect extends StatelessWidget {
  final double? height;
  final double? width;

  final EdgeInsets margin;
  final EdgeInsets padding;

  final BoxDecoration? inactiveCosmetic;
  final BoxDecoration? hoveringCosmetic;

  final AlignmentGeometry? align;

  final Widget? child;

  HoverEffect({
    super.key,
    this.child,
    this.align,
    this.height,
    this.width,
    this.inactiveCosmetic,
    this.hoveringCosmetic,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) => Hoverable().build(
    (context, hovering, _) => Container(
      height: height,
      width: width,
      alignment: align,
      margin: margin,
      padding: padding,
      decoration: hovering ? hoveringCosmetic : inactiveCosmetic,
      child: child,
    ), cursor: SystemMouseCursors.basic
  );
}

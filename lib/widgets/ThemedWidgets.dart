// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';

import 'Style.dart';
import 'Verticatrix.dart';

Verticatrix buildVerticatrix(
  ColorScheme scheme,
  TextTheme textTheme,
  VerticatrixController controller,
  HeaderBuilder headerBuilder,
  RowHeaderBuilder rowHeaderBuilder,
  ChangeNotifier rowHeaderRebuildNotifier,
  Iterable<(String, String, RegionVisitor<String>)> formatters,
  { bool showHeaderBackground = true }
) => Verticatrix(
  controller: controller,
  headerBuilder: headerBuilder,
  rowHeaderBuilder: rowHeaderBuilder,
  rowHeaderRebuildNotifier: rowHeaderRebuildNotifier,
  formatters: formatters,
  headerExtraSpace: cellPadding + 48,
  cellHeight: cellHeight,
  cellPadding: const EdgeInsets.symmetric(horizontal: cellPadding),
  textStyle: textTheme.bodyMedium!,
  ctxMenuTextStyle: textTheme.titleMedium!,
  evenRowColor: scheme.surfaceContainerHigh,
  ctxMenuColor: scheme.surface,
  colEdgeColor: scheme.onSurface,
  headerBackground: showHeaderBackground ? scheme.surface : Colors.transparent,
  selectedRegionOutline: BoxDecoration(
    border: Border.all(color: scheme.primary),
    boxShadow: [BoxShadow(
      color: scheme.primary,
      blurStyle: BlurStyle.outer,
      blurRadius: 1.2,
    )]
  ),
);

Icon buildIcon(IconData icon, ColorScheme scheme, bool hovering, {
  double size = 18
}) => Icon(
  icon,
  size: size,
  color: hovering ? scheme.primary : scheme.onSurfaceVariant
);

Icon buildClearIcon(ColorScheme scheme, bool hovering, {
  double size = 18
}) => Icon(
  Icons.cancel,
  size: size,
  color: hovering ? scheme.error : scheme.onSurfaceVariant
);

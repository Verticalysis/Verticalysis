// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';

const lightColorContent = Color(0xFF303030);
const lightColorOptions = Color(0xFF878787);
const optionHovered =  Color(0x2100DCD6);
const optionActive =  Color(0xAA00DCD6);
const transparent =  Color(0xAA00DCD6);

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  onPrimaryContainer: lightColorContent,      // content text
  primary: const Color(0xFF00DCD6),
  onPrimary: const Color(0xFFFFFFFF),
  onPrimaryFixed: const Color(0xFF56CBC3),    // theme color variant for text background
  secondary: const Color(0xFF0099FF),
  onSecondary: const Color(0xFFFFFFFF),
  error: const Color(0xFFDC362E),
  onError: const Color(0xFF601410),
  surface: const Color(0xFFF6F6F6),
  surfaceDim: const Color(0xFFDCDCDC),        // Hovered tab
  surfaceBright: const Color(0xFFECECEC),     // Widget on surface hovered
  onSurface: const Color(0xFFC6C6C6),         // Input boarder / column ruler
  onSurfaceVariant: const Color(0xFFA9A9A9),  // Faded Text
  surfaceContainer: const Color(0xFFFFFFFF),  // List / Verticatrix region
  surfaceContainerHigh: const Color(0x05000000),
);

final lightColorTheme = ThemeData(
  colorScheme: lightColorScheme,
  textTheme: const TextTheme(
    titleSmall: TextStyle(
      color: lightColorOptions, fontSize: 13.2, fontWeight: FontWeight.w400
    ),
    titleMedium: TextStyle(
      color: lightColorOptions, fontSize: 15, fontWeight: FontWeight.w400
    ), // Dropdown menu items
    bodyMedium: TextStyle(color: lightColorContent, fontSize: 13.2),
    bodyLarge: TextStyle(color: lightColorContent, fontSize: 15),
    labelLarge: TextStyle(color: lightColorContent, fontSize: 19, fontWeight: FontWeight.w400), // scaled Dropdown options
    labelMedium: TextStyle(color: lightColorContent, fontSize: 15, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(
      color: const Color(0xFFCCCCCC),
      fontWeight: FontWeight.w100,
      fontSize: 12,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(color: lightColorScheme.onSurfaceVariant),
    fillColor: lightColorScheme.surfaceContainer,
    hoverColor: lightColorScheme.surfaceContainer,
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(
      color: lightColorScheme.onSurface, width: 0.6
    ), borderRadius: const BorderRadius.all(Radius.circular(6.0))),
    disabledBorder: OutlineInputBorder(borderSide: BorderSide(
      color: lightColorScheme.onSurface, width: 0.6
    ), borderRadius: const BorderRadius.all(Radius.circular(6.0))),
    errorBorder: OutlineInputBorder(borderSide: BorderSide(
      color: lightColorScheme.error, width: 0.6
    ), borderRadius: const BorderRadius.all(Radius.circular(6.0))),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(
      color: lightColorScheme.primary, width: 0.6
    ), borderRadius: const BorderRadius.all(Radius.circular(6.0))),
    focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(
      color: lightColorScheme.error, width: 0.6
    ), borderRadius: const BorderRadius.all(Radius.circular(6.0))),
    isDense: true,
    filled: true,
  ),
  tooltipTheme: TooltipThemeData(
    decoration: BoxDecoration(
      color: lightColorScheme.onPrimaryFixed,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
    ),
    textStyle: const TextStyle(color: Color(0xFFFFFFFF)),
  ),
  splashFactory: const NoSplashFactory(),
  splashColor: const Color(0x00000000),
  highlightColor: const Color(0x00000000),
  hoverColor: const Color(0x00000000),
  useMaterial3: true,
);

final menuItemStyle = MenuItemButton.styleFrom(
  enabledMouseCursor: SystemMouseCursors.basic,
  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 15),
  textStyle: TextStyle(fontSize: 15),
  overlayColor: const Color(0xFF00DCD6)
);

final menuIconStyle = MenuItemButton.styleFrom(
  enabledMouseCursor: SystemMouseCursors.basic,
  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 15),
  textStyle: TextStyle(fontSize: 15),
  overlayColor: const Color(0xFF00DCD6)
);

final optionItemStyle = MenuItemButton.styleFrom(
  enabledMouseCursor: SystemMouseCursors.basic,
  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
  textStyle: TextStyle(fontSize: 13.2),
  overlayColor: const Color(0xFF00DCD6)
);

// final darkColorScheme

const rectBorder = BorderRadius.all(Radius.zero);
const cellHeight = 30.0;
const cellPadding = 10.0;

final class NoSplashFactory extends InteractiveInkFeatureFactory {
  const NoSplashFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved
  }) => NoSplash(
    controller: controller,
    referenceBox: referenceBox,
  );
}

final class NoSplash extends InteractiveInkFeature {
  NoSplash({
    required MaterialInkController controller,
    required RenderBox referenceBox,
  }): super(
    color: const Color(0x00000000),
    controller: controller,
    referenceBox: referenceBox,
  );

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {}
}

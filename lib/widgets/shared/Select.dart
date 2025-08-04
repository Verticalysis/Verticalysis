// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';

import 'Clickable.dart';

final class Select<T> extends StatelessWidget {
  Select({
    required T initialValue,
    required this.anchorBuilder,
    required this.optionsBuilder,
    this.alignmentOffset,
    this.dropdownIconColor,
    this.controller,
    ValueNotifier<T>? selected
  }): _selected = selected ?? ValueNotifier(initialValue);

  final Widget Function(
    BuildContext context, T selected, Widget dropdownIcon
  ) anchorBuilder;

  final List<Widget> Function(
    BuildContext context, void Function(T _) onTap
  ) optionsBuilder;

  final Offset? alignmentOffset;
  final Color? dropdownIconColor;

  final ValueNotifier<T> _selected;
  final MenuController? controller;

  @override
  Widget build(BuildContext context) => MenuAnchor(
    alignmentOffset: alignmentOffset,
    controller: controller,
    menuChildren: optionsBuilder(context, _selected.setValue),
    builder: (context, controller, _) => ValueListenableBuilder(
      valueListenable: _selected,
      child: buildDropdownIcon(controller),
      builder: (context, selected, icon) => anchorBuilder(
        context, selected, icon!
      )
    )
  );

  Widget buildDropdownIcon(MenuController controller) => Clickable(
    Icon(Icons.arrow_drop_down, color: dropdownIconColor, size: 18),
    onClick: () => controller.isOpen ? controller.close() : controller.open()
  );
}

extension<T> on ValueNotifier<T> {
  void setValue(T value) => this.value = value;
}

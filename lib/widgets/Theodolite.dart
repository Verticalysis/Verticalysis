// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.


import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import 'helper/Events.dart';

final class TheodoliteController {
  final columnsSpecifier  = TextEditingController();
  final entriesSpecifier = TextEditingController();

  final Channel<Notifer2<String?, int?>> _requestTeleport;

  TheodoliteController(
    EventDispatcher dispatcher
  ): _requestTeleport = dispatcher.getChannel(Event.requestTeleport) {
    dispatcher.listen(Event.selectRegionUpdate, (
      int startRow, int endRow, Iterable<(String, List<String?>)> columns
    ) => onSelectionUpdate((Iterable<(String, List<String?>)> columns) sync* {
      for(final (name, _) in columns) yield name;
    } (columns), startRow, endRow));
  }

  void onSelectionUpdate(Iterable<String> columns, int startRow, int endRow) {
    entriesSpecifier.text = "$startRow^${endRow - startRow}";
    columnsSpecifier.text = columns.join(",");
  }

  void dispose() {
    columnsSpecifier.dispose();
    entriesSpecifier.dispose();
  }
}

final class Theodolite extends StatelessWidget {
  final _columnsAccess = ValueNotifier(false);
  final _leftIconHovered = ValueNotifier(false);
  final _rightIconHovered = ValueNotifier(false);

  final double expandedWidth;
  static const double _collapsedWidth = 39;

  final TheodoliteController _controller;

  Theodolite(this._controller, this.expandedWidth);

  @override
  Widget build(BuildContext context) => Row(
    spacing: 3,
    children: [
      ValueListenableBuilder(
        valueListenable: _columnsAccess,
        builder: (context, columnsAccess, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 40,
          width: columnsAccess ? expandedWidth : _collapsedWidth,
          child: ValueListenableBuilder(
            valueListenable: _leftIconHovered,
            builder: (context, iconHovered, _) => TextField(
              onSubmitted: _onSubmit,
              readOnly: !columnsAccess,
              controller: _controller.columnsSpecifier,
              decoration: _buildDecoration(
                hintText: "columns ...",
                colorScheme: ColorScheme.of(context),
                activated: columnsAccess,
                hovered: iconHovered,
                prefixIcon: _buildIcon(
                  const Icon(Icons.amp_stories_rounded, size: 30),
                  _leftIconHovered,
                  true
                )
              ),
            )
          )
        )
      ),
      ValueListenableBuilder(
        valueListenable: _columnsAccess,
        builder: (context, columnsAccess, _) => AnimatedContainer(
          height: 40,
          duration: const Duration(milliseconds: 300),
          width: !columnsAccess ? expandedWidth : _collapsedWidth,
          child: ValueListenableBuilder(
            valueListenable: _rightIconHovered,
            builder: (context, iconHovered, _) => TextField(
              onSubmitted: _onSubmit,
              cursorHeight: 18,
              readOnly: columnsAccess,
              controller: _controller.entriesSpecifier,
              decoration: _buildDecoration(
                hintText: "entries ...",
                colorScheme: ColorScheme.of(context),
                activated: !columnsAccess,
                hovered: iconHovered,
                suffixIcon: _buildIcon(const RotatedBox(
                  quarterTurns: 1,
                  child: Icon(Icons.amp_stories_rounded, size: 30)
                ), _rightIconHovered, false)
              ),
            )
          )
        )
      ),
    ]
  );

  void _onSubmit(String _) {
    final columns = _controller.columnsSpecifier.text;
    final entries = _controller.entriesSpecifier.text;
    if(columns == "" && entries == "") return;
    final targetEntry = int.tryParse(entries);
    final targetColumns = columns.split(",");
    if(targetColumns case [ final single ]) {
      if(single == "") {
        if(targetEntry == null) {
          _notifyError("row number", entries);
        } else _controller._requestTeleport.notify(null, targetEntry);
      } else { // one column as the target
        if(targetEntry == null) {
          // TODO: implement region selection for a single column
        } else _controller._requestTeleport.notify(single, targetEntry);
      }
    } // TODO: implement region selection for multiple columns
  }

  void _notifyError(String target, String raw) => FlutterPlatformAlert.showAlert(
    windowTitle: "Invalid input",
    text: "$raw is not a valid $target",
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );

  Widget _buildIcon(
    Widget icon, ValueNotifier<bool> hovering, bool columnsAccess
  ) => MouseRegion(
    onHover: (_) => hovering.value = true,
    onExit: (_) => hovering.value = false,
    child: GestureDetector(
      child: icon,
      onTap: () {
        _leftIconHovered.value = false;
        _rightIconHovered.value = false;
        _columnsAccess.value = columnsAccess;
      }
    )
  );

  static InputDecoration _buildDecoration({
    required ColorScheme colorScheme,
    required String hintText,
    required bool activated,
    required bool hovered,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: activated ? hintText : null,
    fillColor: activated ? null: colorScheme.surface,
    hoverColor: activated ? null: colorScheme.surface,
    contentPadding: const EdgeInsets.fromLTRB(12, 12, 9, 13),
    enabledBorder: activated || hovered ? null : InputBorder.none,
    disabledBorder: activated ? null : InputBorder.none,
    errorBorder: activated ? null : InputBorder.none,
    focusedBorder: activated ? null : InputBorder.none,
    focusedErrorBorder: activated ? null : InputBorder.none,
    prefixIcon: activated ? null : prefixIcon,
    suffixIcon: activated ? null : suffixIcon
  );
}

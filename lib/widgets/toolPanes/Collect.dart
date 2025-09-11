// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';

import '../../models/PipelineModel.dart';
import '../../models/ProjectionsModel.dart';
import '../../models/SelectionsModel.dart';
import '../helper/Events.dart';
import '../helper/Formatter.dart';
import '../helper/MonitorModeController.dart';
import '../shared/Decorations.dart';
import '../Style.dart';
import '../ThemedWidgets.dart';
import '../Verticell.dart';
import '../Verticatrix.dart';

/// The collect tool in the toolset
final class Collect extends StatelessWidget {
  final MonitorModeController mmc;
  final ProjectionsModel _projections;

  SelectionsModel get _selections => mmc.selectionsModel;

  final _expandHeaders = ValueNotifier(true);

  final primaryVcxController = VerticatrixController();
  final VerticatrixController linkedVcxController;

  static final phonyChangeNotifier = PhonyChangeNotifier();

  Collect(this.mmc, this._projections, this.linkedVcxController) {
    mmc.listen(Event.newColumns, (_) => syncAll());
    mmc.listen(Event.collectionAppend, (int index) {
      _projections.current.include([index]);
      primaryVcxController.entries = _projections.current.length;
      syncAll();
    });
    mmc.listen(Event.collectionRemove, (int row) {
      _projections.current.remove(row);
      primaryVcxController.entries = _projections.current.length;
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface,
        boxShadow: [BoxShadow(
          color: ColorScheme.of(context).onSurface,
          blurRadius: 0.6
        )]
      ),
      child: Row(
        spacing: 6,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Add all selections",
            icon: Icon(
              Icons.add, size: 15, color: ColorScheme.of(context).onSurface
            ),
            padding: const EdgeInsets.all(3),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: rectBorder),
              fixedSize: const Size.square(13.5)
            ),
            onPressed: () {
              _projections.current.include(_selections.selections.toList());
              primaryVcxController.syncWith(linkedVcxController);
              syncAll();
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Clear",
            icon: Icon(
              Icons.delete, size: 15, color: ColorScheme.of(context).onSurface
            ),
            padding: const EdgeInsets.all(3),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: rectBorder),
              fixedSize: const Size.square(13.5)
            ),
            onPressed: () {
              primaryVcxController.entries = 0;
              _projections.current.clear();
            }
          ),
          Vdivider(color: ColorScheme.of(context).onSurface),
          /*CheckboxListTile(
            title: Text("Track selections"),
            value: checkedValue,
            onChanged: (newValue) { ... },
            controlAffinity: ListTileControlAffinity.leading,
          ),*/
          SizedBox(
            width: 270,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: "Search...",
                filled: true,
                fillColor: ColorScheme.of(context).surface,
                hoverColor: ColorScheme.of(context).surfaceBright,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 9, horizontal: 12
                ),
              ),
              onSubmitted: (keyWord) {

              },
            )
          ),
          Spacer(),
          ValueListenableBuilder(
            valueListenable: _expandHeaders,
            builder: (context, expandHeaders, _) => IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: expandHeaders ? "Hide Headers" : "Show Headers",
              icon: RotatedBox(
                quarterTurns: expandHeaders ? 0 : 2,
                child: Icon(
                  Icons.keyboard_capslock,
                  size: 15,
                  color: ColorScheme.of(context).onSurface
                )
              ),
              padding: const EdgeInsets.all(3),
              style: IconButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: rectBorder),
                fixedSize: const Size.square(13.5)
              ),
              onPressed: () => _expandHeaders.value = !expandHeaders,
            ),
          )
        ]
      ),
    ),
    Expanded(child: ListenableBuilder(
      listenable: _projections,
      builder: (_, _) => ValueListenableBuilder(
        valueListenable: _expandHeaders,
        builder: (context, expandHeaders, _) => buildVerticatrix(
          ColorScheme.of(context),
          TextTheme.of(context),
          syncAll(),
          expandHeaders ?
          CollectHeaderBuilder(_projections).build :
          (_, _, _, _) => SizedBox.shrink(),
          CollectRowHeaderBuilder(mmc).build,
          phonyChangeNotifier,
          Formatter.formatters,
          showHeaderBackground: expandHeaders
        )
      )
    ))
  ]);

  VerticatrixController syncAll() => primaryVcxController..syncWith(
    linkedVcxController
  )..syncColumns((id) {
    return _projections.getColumn(id, mmc.pipelineModel.getAttrTypeByName);
  }, _projections.current.length);
}

class PhonyChangeNotifier extends ChangeNotifier {}

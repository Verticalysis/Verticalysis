// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math' show min;

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../models/PlotterModel.dart';
import '../../models/PipelineModel.dart';
import '../../models/ProjectionsModel.dart';
import '../shared/Clickable.dart';
import '../shared/Extensions.dart';
import '../shared/Decorations.dart';
import '../shared/NestedMenu.dart';
import '../shared/Select.dart';
import '../Style.dart';

enum LineType {
  Segement,
  Smooth,
  None,
}


final class Plotter extends StatelessWidget {
  Plotter(this._plotterModel, this._projectionsModel, this._pipelineModel);

  final PlotterModel _plotterModel;
  final PipelineModel _pipelineModel;
  final ProjectionsModel _projectionsModel;

  // x-axis, defaults to the index if null
  final _reference = ValueNotifier("");
  final _lineType = ValueNotifier(LineType.Smooth);
  final _showTitle = ValueNotifier(false);
  final _showLegend = ValueNotifier(false);
  final _showVgrids = ValueNotifier(false);

  charts.Series<int, num> getPoints(String trace, Color color) {
    final domain = switch(_reference.value) {
      "" => Iota(_projectionsModel.currentLength),
      final String column => _projectionsModel.getColumn(
        column, _pipelineModel.getAttrTypeByName
      ).typedView as List<num?>
    };

    final measure = _projectionsModel.getColumn(
      trace, _pipelineModel.getAttrTypeByName
    ).typedView as List<num?>;

    final intColor = charts.Color(
      r: (color.r * 255).round(),
      g: (color.g * 255).round(),
      b: (color.b * 255).round()
    );

    return charts.Series<int, num>(
      id: 'Primary',
      data: Iota(_projectionsModel.currentLength),
      domainFn: (index, _) => domain[index] ?? 0,
      measureFn: (index, _) => measure[index],
      colorFn: (_, _) => intColor
    );
  }

  @override
  Widget build(BuildContext context) => /*ValueListenableBuilder(
    valueListenable: _plotType,
    builder: (context, plotType, _) => */ Column(children: [
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
            tooltip: "Remove all",
            icon: Icon(
              Icons.delete, size: 15, color: ColorScheme.of(context).onSurface
            ),
            padding: const EdgeInsets.all(3),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: rectBorder),
              fixedSize: const Size.square(13.5)
            ),
            onPressed: () => _plotterModel.clearTrace(),
          ),
          NestedMenu([
            MenuItemButton(
              style: optionItemStyle,
              child: Text("PNG", style: TextTheme.of(context).titleMedium)
            ),
            MenuItemButton(
              style: optionItemStyle,
              child: Text("SVG", style: TextTheme.of(context).titleMedium)
            ),
          ]).withIcon(
            Icon(Icons.drive_file_move, color: ColorScheme.of(context).onSurface),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(3),
            tooltip: "Export plot to file",
          ),
          NestedMenu([
            buildToggleItem(context, _showTitle, "Title"),
            buildToggleItem(context, _showLegend, "Legend"),
            buildToggleItem(context, _showVgrids, "Vertical rulers"),
          ]).withIcon(
            Icon(Icons.visibility, color: ColorScheme.of(context).onSurface),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(3),
            tooltip: "Show",
          ),
          Vdivider(color: ColorScheme.of(context).onSurface),
          /* TODO: implement export plot to clipboard
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Export plot to clipboard",
            icon: Icon(
              Icons.content_paste_go,
              color: ColorScheme.of(context).onSurface,
              size: 15,
            ),
            padding: const EdgeInsets.all(3),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: rectBorder),
              fixedSize: const Size.square(13.5)
            ),
            onPressed: () {},
          ),*/
          const SizedBox(width: 9),
          Text("Variable:", style: TextTheme.of(context).titleSmall),
          Select<String>(
            initialValue: "",
            selected: _reference,
            alignmentOffset: const Offset(-9, 0),
            dropdownIconColor:ColorScheme.of(context).onSurfaceVariant,
            anchorBuilder: (context, selected, icon) => SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [ Text(selected), icon ]
              ),
            ),
            optionsBuilder: (context, onTap) => [
              for(final attr in _pipelineModel.declaredAttributes) MenuItemButton(
                style: optionItemStyle,
                onPressed: () => onTap(attr.name),
                child: Text(attr.name),
              ),
            ]
          ),
          const SizedBox(width: 9),
          Text("Show", style: TextTheme.of(context).titleSmall),
          ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 78),
              child: IntrinsicWidth(child: TextField(
                style: TextTheme.of(context).titleSmall,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "all points",
                  suffixText: "points",
                  hintStyle: TextTheme.of(context).titleSmall,
                  filled: true,
                  fillColor: ColorScheme.of(context).surface,
                  hoverColor: ColorScheme.of(context).surfaceBright,
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.fromLTRB(3, 10, 3, 11),
                ),
                onSubmitted: (count) {

                },
              )
            )
          ),
          const Spacer(),
          NestedMenu([
          ]).withIcon(
            Icon(Icons.more_horiz, color: ColorScheme.of(context).onSurface),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            padding: const EdgeInsets.all(1.5),
            tooltip: "Options",
          ),
          /*Text("Line Style:", style: TextTheme.of(context).titleSmall),
          DropdownMenu<LineType>(
            width: 180,
            requestFocusOnTap: false,
            initialSelection: LineType.Smooth,
            onSelected: (type) => _lineType.value = type!,
            dropdownMenuEntries: LineType.values.map(
              (type) => DropdownMenuEntry(label: type.name, value: type)
            ).toList(),
            textStyle: TextTheme.of(context).labelLarge,
            inputDecorationTheme: _dropDownTheme
          ).scale(height: 33)*/
        ]
      )

    ),
    Expanded(child: Row(children: [
      SizedBox(
        width: 240,
        child: ListenableBuilder(
          listenable: _plotterModel,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(12, 3, 9, 3),
            children: [ for(final trace in _plotterModel.traces) Row(
              spacing: 9,
              children: [
                Clickable(
                  ColoredBox(
                    color: _plotterModel.colorOf(trace),
                    child: const SizedBox(height: 15, width: 15)
                  ),
                  onClick: () {
                    late OverlayEntry palette;
                    palette = OverlayEntry(builder: (context) => Positioned(
                      bottom: 42,
                      left: 36,
                      child: MouseRegion(
                        onExit: (_) => palette.remove(),
                        child: Material(child: Container(
                          width: 642,
                          height: 180,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: ColorScheme.of(context).surface,
                            boxShadow: [BoxShadow(
                              offset: const Offset(1.0, 1.0),
                              color: ColorScheme.of(context).onSurface,
                              blurRadius: 1.5
                            )]
                          ),
                          child: ColorPicker(
                            pickerColor: _plotterModel.colorOf(trace),
                            onColorChanged: (c) => _plotterModel.setColor(trace, c),
                            colorPickerWidth: 300,
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: true,
                            labelTypes: const [
                              ColorLabelType.rgb,
                              ColorLabelType.hex,
                              ColorLabelType.hsv,
                            ],
                            displayThumbColor: true,
                            hexInputBar: false,
                            paletteType: PaletteType.hsv,
                            pickerAreaBorderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              topRight: Radius.circular(2),
                            ),
                          )
                        )))
                      )
                    );
                    Overlay.of(context).insert(palette);
                  }
                ),
                SizedBox(
                  height: 27,
                  width: 159,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: trace,
                      child: Text(
                        trace,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      )
                    ),
                  )
                ),
                Spacer(),
                Clickable(
                  Icon(
                    Icons.close,
                    color: ColorScheme.of(context).onSurface,
                    size: 15,
                  ),
                  onClick: () => _plotterModel.removeTrace(trace)
                ),
              ],
            )],
          ),
        )
      ),
      Expanded(child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(border: Border(left:
          BorderSide(width: 0.5, color: ColorScheme.of(context).onSurface)
        )),
        child: ListenableBuilder(
          listenable: _plotterModel,
          builder: (context, _) => charts.LineChart(
            _plotterModel.traces.isNotEmpty ? [ for(
              final trace in _plotterModel.traces
            ) getPoints(
              trace, _plotterModel.colorOf(trace)
            ) ] : [ charts.Series<int, num>(
              id: 'Primary',
              data: Iota(_projectionsModel.currentLength),
              domainFn: (index, _) => 0,
              measureFn: (index, _) => 0,
              colorFn: (_, _) => charts.Color(r: 0, g: 0, b: 0, a: 0)
          ) ], animate: true)
        )
      ))
    ]))
  ]);

  static Widget buildToggleItem(
    BuildContext context,
    ValueNotifier<bool> notifer,
    String label
  ) => MenuItemButton(
    style: optionItemStyle,
    onPressed: () => notifer.value = !notifer.value,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextTheme.of(context).titleMedium),
        ValueListenableBuilder(
          valueListenable: notifer,
          builder: (context, showLegend, _) => showLegend ? Icon(
            Icons.check, size: 18,
          ) : const SizedBox(width: 42),
        )
      ]
    )
  );

  static const _dropDownTheme = InputDecorationTheme(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 6),
    enabledBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}


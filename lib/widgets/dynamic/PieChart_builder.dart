// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

import 'utils.dart';

part 'PieChart_builder.g.dart';

@jsonWidget
abstract class _PieChartBuilder extends JsonWidgetBuilder {
  const _PieChartBuilder({
    required super.args,
  });

  @override
  _PieChart buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}

class _PieChart extends StatelessWidget {
  const _PieChart({
    Map data = const {},
    bool animate = false,
    int principleColor = 0xFF00DCD6,
    Map? legendConfig
  }) : _data = data,
      _animate = animate,
      _principleColor = principleColor,
      _legendConfig = legendConfig;

  final Map _data;
  final int _principleColor;
  final bool _animate;
  final Map? _legendConfig;

  @override
  Widget build(BuildContext context) => charts.PieChart(
    [ charts.Series<MapEntry, String>(
        id: 'primary',
        colorFn: (_, index) {
          final palette = AsymptoticPalette(_principleColor);
          final color = palette[index!.toDouble()];
          return charts.Color(
            a: (color >> 24) & 0xFF,
            r: (color >> 16) & 0xFF,
            g: (color >> 8) & 0xFF,
            b: color & 0xFF
          );
        },
        domainFn: (_data, _) => _data.key as String,
        measureFn: (_data, _) => _data.value as int,
        data: _data.entries.toList(),
    ) ],
    animate: _animate,
    behaviors: _legendConfig != null ? ([
      charts.DatumLegend<Object>(
        // Positions for "start" and "end" will be left and right respectively
        // for widgets with a build context that has directionality ltr.
        // For rtl, "start" and "end" will be right and left respectively.
        // Since this example has directionality of ltr, the legend is
        // positioned on the right side of the chart.
        position: _legendPositions[_legendConfig["position"]],
        // For a legend that is positioned on the left or right of the chart,
        // setting the justification for [endDrawArea] is aligned to the
        // bottom of the chart draw area.
        outsideJustification: _legendJustification[_legendConfig["justification"]],
        // By default, if the position of the chart is on the left or right of
        // the chart, [horizontalFirst] is set to false. This means that the
        // legend entries will grow as new rows first instead of a new column.
        horizontalFirst: _legendConfig["horizontalFirst"],
        // By setting this value to 2, the legend entries will grow up to two
        // rows before adding a new column.
        desiredMaxRows: _legendConfig["maxRows"],
        // This defines the padding around each legend entry.
        cellPadding: EdgeInsets.only(
          left: _legendConfig["cellPaddingLeft"] ?? 0,
          top: _legendConfig["cellPaddingTop"] ?? 0,
          right: _legendConfig["cellPaddingRight"] ?? 0,
          bottom: _legendConfig["cellPaddingBottom"] ?? 0
        ),
        // Render the legend entry text with custom styles.
        entryTextStyle: charts.TextStyleSpec(
          fontFamily: _legendConfig["fontFamily"],
          fontSize: _legendConfig["fontSize"]
        ),
      )
    ]) : null
  );

  static const _legendPositions = {
    "start": charts.BehaviorPosition.start,
    "end": charts.BehaviorPosition.end,
  };

  static const _legendJustification = {
    "start": charts.OutsideJustification.startDrawArea,
    "end": charts.OutsideJustification.endDrawArea,
  };
}

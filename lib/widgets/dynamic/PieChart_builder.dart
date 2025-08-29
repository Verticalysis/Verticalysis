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
  }): _data = data, _animate = animate, _principleColor = principleColor;

  final Map _data;
  final int _principleColor;
  final bool _animate;

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
  );
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

part 'BarChart_builder.g.dart';

@jsonWidget
abstract class _BarChartBuilder extends JsonWidgetBuilder {
  const _BarChartBuilder({
    required super.args,
  });

  @override
  _BarChart buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    Map data = const {},
    bool animate = false,
    int color = 0xFF00DCD6,
  }): _data = data, _animate = animate, _color = color;

  final Map _data;
  final bool _animate;
  final int _color;

  @override
  Widget build(BuildContext context) => charts.BarChart(
    [ charts.Series<MapEntry, String>(
        id: 'primary',
        colorFn: (_, _) => charts.Color(
          a: (_color >> 24) & 0xFF,
          r: (_color >> 16) & 0xFF,
          g: (_color >> 8) & 0xFF,
          b: _color & 0xFF
        ),
        domainFn: (_data, _) => _data.key as String,
        measureFn: (_data, _) => _data.value as int,
        data: _data.entries.toList(),
    ) ],
    animate: _animate,
  );
}

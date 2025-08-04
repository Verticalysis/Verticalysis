// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:json_dynamic_widget/json_dynamic_widget.dart';

import '../../domain/analysis/Analyzer.dart';
import '../../domain/analysis/builtin/NumericAnalyzer.dart';
import '../../domain/analysis/builtin/RegressionAnalyzer.dart';
import '../../domain/analysis/builtin/StatisticAnalyzer.dart';


extension type AnalyzerInitializerRegistry._(
  JsonWidgetRegistry reg
) implements JsonWidgetRegistry {
  AnalyzerInitializerRegistry(
    Map<String, dynamic> options
  ): reg = JsonWidgetRegistry(
    values: options, functions: _routines
  );

  static dynamic setBool ({
    required args, required registry
  }) => (bool? onChangedValue) {
    final variableName = args![0];
    registry.setValue(variableName, onChangedValue);
  };

  static const _routines = {
    'setBool': setBool
  };
}

final class AnalyzersCotroller {
  AnalyzersCotroller() {
    updatePanel(0);
  }

  JsonWidgetData _panelBlueprint = JsonWidgetData.fromDynamic(
    const { "type": "placeholder", "args": {} }
  );

  Map<String, Object> options = {};

  int get analyzers => _builtin.length;

  /// don't make it static as we may load plugins as analyzers in the future
  Analyzer enumerate(int index) => _builtin[index];

  int updatePanel(int index) {
    final analyzer = enumerate(index);
    options = Map.from(analyzer.options);
    _panelBlueprint = JsonWidgetData.fromDynamic(
      analyzer.configPanel, registry: AnalyzerInitializerRegistry(options)
    );
    return index;
  }

  Widget buildPanel(BuildContext ctx) => _panelBlueprint.build(context: ctx);

  Widget vectorAnalysis(
    int index,
    Iterable<GenericCandidate> vector,
    BuildContext ctx
  ) => JsonWidgetData.fromDynamic(
    (enumerate(index) as VectorAnalyzer).analyze(vector, options),
    registry: JsonWidgetRegistry()
  ).build(context: ctx);


  List<Widget> scalarAnalysis(
    int index,
    Iterable<GenericCandidate> vector,
    BuildContext ctx
  ) {
    final res = <Widget>[];
    final analyzer = enumerate(index) as ScalarAnalyzer;
    final iters = vector.map((c) => c.data.iterator).toList();
    while(iters.every(
      (iter) => iter.moveNext()
    )) res.add(JsonWidgetData.fromDynamic(
      analyzer.analyze(vector.asScalar(iters), options),
      registry: JsonWidgetRegistry()
    ).build(context: ctx));
    return res;
  }

  static const _builtin = [
    const NumericAnalyzer(),
    const RegressionAnalyzer(),
    const StatisticAnalyzer(),
  ];
}

extension on Iterable<GenericCandidate> {
  Iterable<(String, AttrType, Comparable?)> asScalar(
    List<Iterator<Comparable?>> row, [ int i = 0 ]
  ) => this.map(
    (candidate) => (candidate.name, candidate.type, row[i++].current)
  );
}

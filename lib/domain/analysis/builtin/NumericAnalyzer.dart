// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../Analyzer.dart';
import 'shared.dart';

final class NumericAnalyzer extends VectorAnalyzer {
  const NumericAnalyzer();

  @override
  Map<String, dynamic> get configPanel => MultiColumn([
    [
      LabeledCheckbox("Average", "average"),
      LabeledCheckbox("Median", "median"),
      LabeledCheckbox("Maximum", "maximum"),
      LabeledCheckbox("Minimum", "minimum"),
    ],
    [
      LabeledCheckbox("Extreme Deviation", "extremeDeviation"),
      LabeledCheckbox("Standard Deviation", "standardDeviation"),
      LabeledCheckbox("Interquartile Range", "interquartileRange"),
      LabeledCheckbox("Summation", "summation")
    ]
  ]);

  @override
  bool applicable(
    Iterable<AttrType<Comparable>> attributes
  ) => attributes.length == 1 && attributes.first.allowCast<num>();

  @override
  Map<String, dynamic> analyze(
    Iterable<GenericCandidate> vector, Map<String, Object> options
  ) => {
    "type": "column",
    "args": {
      "children": [
        {
          "type": "text",
          "args": {
            "text": "Average",
            "style": {
              "color": "#000",
              "fontSize": 18
            }
          }
        }
      ]
    }
  };

  @override
  String get name => "Numeric";

  @override
  Map<String, Object> get options => const {
    "summation": true,
    "average": true,
    "median": true,
    "maximum": true,
    "minimum": true,
    "extremeDeviation": true,
    "standardDeviation": true,
    "interquartileRange": true
  };
}

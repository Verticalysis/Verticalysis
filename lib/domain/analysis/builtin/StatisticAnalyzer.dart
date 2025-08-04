// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../Analyzer.dart';

final class StatisticAnalyzer extends VectorAnalyzer {
  const StatisticAnalyzer();



  @override
  Map<String, dynamic> get configPanel => const {"type": "column",
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
  String get name => "Statistic";

  @override
  Map<String, Object> get options => const {
    "unique": true,
    "frequency": true,
    "histogram": true
  };
}

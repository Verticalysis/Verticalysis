// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../../utils/Collections.dart';
import '../Analyzer.dart';
import 'shared.dart';

final class RowRef {
  final int _index;
  final Iterable<GenericCandidate> _data;

  RowRef(this._data, this._index);

  Iterable<Comparable?> get data => _data.map((col) => col.data[_index]);

  String get joined => data.join(", ");

  @override
  int get hashCode => data.map(
    (val) => val == null ? 0 : val.hashCode
  ).reduce((lhs, rhs) => _combineHashes(lhs, rhs));

  @override
  bool operator ==(Object other) => switch(other) {
    final RowRef rhs => data.equals(rhs.data),
    _ => false
  };

  int _combineHashes(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash = hash ^ (hash >> 6);
    return hash;
  }
}

final class StatisticAnalyzer extends VectorAnalyzer {
  const StatisticAnalyzer();

  @override
  Map<String, dynamic> get configPanel => MultiColumn([
    [
      LabeledCheckbox("Histogram", "histogram"),
      LabeledCheckbox("Pie Chart", "pieChart"),
    ],
  ]);

  @override
  bool applicable(
    Iterable<AttrType<Comparable>> attributes
  ) => attributes.length == 1 && attributes.first.allowCast<num>();

  @override
  Map<String, dynamic> analyze(
    Iterable<GenericCandidate> vector, Map<String, Object> options
  ) {
    final frequencies = <RowRef, int>{};

    final rowCount = vector.first.data.length;

    for(int rowIndex = 0; rowIndex < rowCount; rowIndex++) frequencies.update(
      RowRef(vector, rowIndex), (i) => i + 1, ifAbsent: () => 1
    );

    if(vector.length == 1 && vector.first.data is List<num>) {
      // TODO: sort frequencies according to vector.first.data
    }

    final plotData = Map<String, int>.fromEntries(frequencies.entries.map(
      (entry) => MapEntry(entry.key.joined, entry.value)
    ));

    return {
      "type": "single_child_scroll_view",
      "args": { "child": Padded.symmetric(12, 12, {
        "type": "column",
        "args": {
          "spacing": 10,
          "children": [
            if(options["histogram"] as bool) {
              "type": "sized_box",
              "args": {
                "height": 128,
                "width": double.infinity,
                "child": {
                  "type": "bar_chart",
                  "args": { "data": plotData }
                }
              }
            },
            {
              "type": "row",
              "args": {
                "mainAxisAlignment": "spaceAround",
                "crossAxisAlignment": "start",
                "children": [
                  {
                    "type": "data_table",
                    "args": {
                      "headingRowHeight": 36,
                      "dataRowMinHeight": 10,
                      "dataRowMaxHeight": 36,
                      "columns": [ "Sample", "Frequency" ],
                      "rows": [
                        for(
                          final MapEntry(:key, :value) in frequencies.entries
                        ) [ key.joined, value.toString() ]
                      ]
                    }
                  },
                  if(options["pieChart"] as bool) {
                    "type": "sized_box",
                    "args": {
                      "height": 150,
                      "width": 360,
                      "child": {
                        "type": "pie_chart",
                        "args": {
                          "data": plotData,
                          "legendConfig": {
                            "position": "end",
                            "cellPaddingBottom": 3.0
                          },
                        }
                      }
                    }
                  }
                ]
              }
            }
          ]
        }
      }) }
    };
  }

  @override
  String get name => "Statistic";

  @override
  Map<String, Object> get options => const {
    "histogram": true,
    "pieChart": true
  };
}

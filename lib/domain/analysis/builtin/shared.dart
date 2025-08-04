// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

typedef Blueprint = Map<String, dynamic>;

extension type LabeledCheckbox._(Blueprint blueprint) implements Blueprint {
  LabeledCheckbox(String label, String variable): blueprint = {
    "type": "row",
    "args": {
      "mainAxisAlignment": "spaceBetween",
      "children": [
        {
          "type": "sized_box",
          "args": {
            "height": 33,
            "width": 33,
            "child": {
              "type": "fitted_box",
                "args": {
                  "child": {
                    "type": "checkbox",
                    "id": variable,
                    "args": {
                      "splashRadius": 0,
                      "label": label,
                      "value": "\${$variable}",
                      "onChanged": "\${setBool('variable')}",
                      "mouseCursor": {
                        "cursor": "basic",
                        "type": "system"
                      }
                    }
                  },
                }
            },
          }
        },
        {
          "type": "text",
          "args": {
            "text": label,
            "style": {
              "fontSize": 15
            }
          }
        }
      ]
    }
  };
}

extension type MultiColumn._(Blueprint blueprint) implements Blueprint {
  MultiColumn(List<List<Blueprint>> columns, [
    double hGap = 30, double vGap = 6
  ]): blueprint = {
    "type": "row",
    "args": {
      "spacing": hGap,
      "children": [ for(final column in columns) {
        "type": "column",
        "args": {
          "crossAxisAlignment": "start",
          "spacing": vGap,
          "children": column
        }
      } ]
    }
  };
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:typed_data';

import '../Analyzer.dart';
import 'shared.dart';

final class IntegerAnalyzer extends ScalarAnalyzer {
  const IntegerAnalyzer();

  @override
  Map<String, dynamic> get configPanel =>  MultiColumn([
    [
      LabeledCheckbox("Binary", "binary"),
      LabeledCheckbox("Decimal", "decimal"),
      LabeledCheckbox("Hex", "hexadecimal"),
    ],
    [
      LabeledCheckbox("Memory layout (BE)", "be"),
      LabeledCheckbox("Memory layout (LE)", "le"),
    ]
  ]);

  @override
  bool applicable(
    Iterable<AttrType<Comparable>> attributes
  ) => attributes.length == 1 && attributes.first.allowCast<num>();

  @override
  Map<String, dynamic> analyze(
    Iterable<(String, AttrType, Comparable?)> scalar, Map<String, Object> options
  ) {
    if(options case {
      "binary":      final bool binaryOpt,
      "decimal":     final bool decimalOpt,
      "hexadecimal": final bool hexOpt,
      "be":          final bool beOpt,
      "le":          final bool leOpt
    }) {
      final (_, _, intValue as int?) = scalar.first;

      if (intValue == null) return {
        "type": "single_child_scroll_view",
        "args": { "child": Padded.symmetric(30, 15, {
          "type": "row",
          "args": {
            "children": [
              LabeledAttribute("Binary: ", "null"),
              MultiColumn([ [
                LabeledAttribute("Decimal: ", "null"),
              ], [
                LabeledAttribute("Hex: ", "null"),
              ] ], 36, 12)
            ]
          } })
        }
      };

      final binary = binaryOpt ? intValue.toRadixString(2) : "-";
      final decimal = decimalOpt ? intValue.toString() : "-";
      final hex = hexOpt ? "0x${intValue.toRadixString(16).toUpperCase()}" : "-";

      String be16 = "-", be32 = "-", be64 = "-";
      String le16 = "-", le32 = "-", le64 = "-";

      if (beOpt || leOpt) {
        // Check if value fits in different integer sizes
        final fits16 = intValue >= -32768 && intValue <= 32767;
        final fits32 = intValue >= -2147483648 && intValue <= 2147483647;
        final fits64 = intValue >= -9223372036854775808 && intValue <= 9223372036854775807;

        if (beOpt) {
          if (fits16) {
            final bytes16 = ByteData(2);
            bytes16.setInt16(0, intValue, Endian.big);
            be16 = bytes16.buffer.asUint8List().map(formatAsHex).join(' ');
          }

          if (fits32) {
            final bytes32 = ByteData(4);
            bytes32.setInt32(0, intValue, Endian.big);
            be32 = bytes32.buffer.asUint8List().map(formatAsHex).join(' ');
          }

          if (fits64) {
            final bytes64 = ByteData(8);
            bytes64.setInt64(0, intValue, Endian.big);
            be64 = bytes64.buffer.asUint8List().map(formatAsHex).join(' ');
          }
        }

        if (leOpt) {
          if (fits16) {
            final bytes16 = ByteData(2);
            bytes16.setInt16(0, intValue, Endian.little);
            le16 = bytes16.buffer.asUint8List().map(formatAsHex).join(' ');
          }

          if (fits32) {
            final bytes32 = ByteData(4);
            bytes32.setInt32(0, intValue, Endian.little);
            le32 = bytes32.buffer.asUint8List().map(formatAsHex).join(' ');
          }

          if (fits64) {
            final bytes64 = ByteData(8);
            bytes64.setInt64(0, intValue, Endian.little);
            le64 = bytes64.buffer.asUint8List().map(formatAsHex).join(' ');
          }
        }
      }

      return  Padded.symmetric(30, 15, {
        "type": "column",
        "args": {
          "spacing": 12,
          "children": [
            LabeledAttribute("Binary: ", binary),
            MultiColumn([ [
              LabeledAttribute("Decimal: ", decimal),
              LabeledAttribute("16-bit BE: ", be16),
              LabeledAttribute("32-bit BE: ", be32),
              LabeledAttribute("64-bit BE: ", be64),
            ], [
              LabeledAttribute("Hex: ", hex),
              LabeledAttribute("16-bit LE: ", le16),
              LabeledAttribute("32-bit LE: ", le32),
              LabeledAttribute("64-bit LE: ", le64),
            ] ], 36, 12)
          ]
        }
      } );
    } else return {}; // unreachable
  }

  @override
  String get name => "Integer";

  @override
  Map<String, Object> get options => const {
    "binary": true,
    "decimal": true,
    "hexadecimal": true,
    "be": true,
    "le": true
  };

  static String formatAsHex(int num) => num.toRadixString(16).padLeft(2, '0');
}

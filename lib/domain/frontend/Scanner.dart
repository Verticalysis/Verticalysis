// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../schema/Schema.dart';
import '../utils/ListView.dart';
import 'adapter/AnnotatedCSVadapter.dart';
import 'adapter/CombinatorialAdapter.dart';
import 'codecvt/UTF8Iterator.dart';
import 'codecvt/Latin1Iterator.dart';
import 'parser/Combinatorial.dart';
import 'parser/CSVparser.dart';
import 'schemaless/TransposeCSV.dart';

/// Composited parser and corresponding adapter to eliminate the discrepancy
/// among result types of different parsers
extension type Scanner(Schema schema) {
  Stream scan(Stream<List<int>> src) => switch(schema) {
    final CustomSchema sch => _customSetups[sch.sourceFormat]!(src, sch),
    final GenericSchema sch => _genericSetups[sch.sourceFormat]!(src)
  };

  static const _genericSetups = {
    "csv": _scanGenericCSV
  };

  static const _customSetups = {
    // "csv": _scanCustomCSV,
    "Custom": _scanCustomFormat,
    "annotated_csv": _scanCustomAnnotatedCSV
  };

  static Stream _scanCustomFormat(
    Stream<List<int>> src, CustomSchema schema
  ) => CombinatorialAdapter(schema).transform(Combinatorial(
    schema.sourceEncoding.decoder,
    schema.customFormatParser,
    schema.customFormatCaptures.length
  ).parse(src));

  static Stream _scanGenericCSV(Stream<List<int>> src) => CSVparser(
    UTF8Iterator.from
  ).parseWithCQ(src).transpose();

  static Stream _scanCustomAnnotatedCSV(
    Stream<List<int>> src, CustomSchema schema
  )  => AnnotatedCSVadapter(
    schema.attributes.where((attr) => attr.nonVoid)
  ).transform(CSVparser(schema.sourceEncoding.decoder).parseWithCQ(src));
}

extension on CSVparser {
  Stream<List<List<String>>> parseWithCQ(Stream<List<int>> src) {
    final commitQueue = <List<String>>[];
    return this.parse(src, () => commitQueue..clear());
  }
}

extension RedirToScanner on Stream<ListView<int>> {
  Stream operator >> (Scanner scanner) => scanner.scan(this);
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../schema/Attribute.dart';
import 'Types.dart';

/// Select texts in a column from a batch of rows and
/// transform them into a sequence list of typed values
/*extension type ColumnCtor._((
  String, Iterable<Comparable?> // returns the attribute name and the lazy list
) Function(List<List<String?>> src) ctor) {
  ColumnCtor(int index, String attr, Xformer xformer): this._(
    (src) => (attr, xformer(src, index))
  );
}*/

extension type ColumnCtor<T extends Comparable>._((
  String, Iterable<T?> // returns the attribute name and the lazy list
) Function(List<List<String?>> src) ctor) {
  ColumnCtor(int index, String attr, Xformer<T> xformer): this._(
    (src) => (attr, src.map((entry) => xformer(entry.elementAtOrNull(index))))
  );
}

extension type Columnarizer._(List<ColumnCtor> _columnCtors) {
  const Columnarizer.bypass(): _columnCtors = const [];

  /// construct a Columnarizer which maps [srcAttrs] into [dstAttrs]
  Columnarizer(
    List<String> srcAttrs, Iterable<Attribute> dstAttrs
  ): _columnCtors = dstAttrs.map<ColumnCtor<Comparable>>(
    (dstAttr) => dstAttr.genericInvoke2(<T extends Comparable>(
      srcAttrs, dstAttr
    ) => ColumnCtor<T>(
      srcAttrs.indexOf(dstAttr.src),
      dstAttr.name,
      dstAttr.xformer as Xformer<T>
    ), srcAttrs, dstAttr)
  ).toList(growable: false);

  Stream<IntakeChunk> process(
    ChunkedStream<List<String?>> src
  ) => src.map((rows) => (_columnCtors.map(
    (ctor) => ctor.ctor(rows)
  ), rows.length));
}

extension RedirToColumnarizer on Stream {
  Stream<IntakeChunk> operator >> (Columnarizer columnarizer) => switch(this) {
    final ChunkedStream<List<String?>> stream => columnarizer.process(stream),
    final Stream<IntakeChunk> stream => stream, // bypass for schemaless setups
    _ => throw TypeError()
  };
}
/*
extension RedirToEvIntakeCtor on ChunkedStream<List<String>> {
  Stream<IntakeChunk> operator >> (
    Columnarizer columnarizer
  ) => columnarizer.process(this);
}

// For schemaless configurations, columnarization is done in the integrated
// frontend and no Columnarizer is needed
extension BypassColumnarizer on Stream<IntakeChunk> {
  Stream<IntakeChunk> operator >> (Columnarizer columnarizer) => this;
}*/

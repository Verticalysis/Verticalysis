// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

import 'Index.dart';
import 'SparseVector.dart';

typedef ColumnVector<T extends Comparable> = SparseVector<T?>;

/// The type parameter T specifies the element type of the exposed [List]
/// interface only. This class can be subclassed to provide a view which
/// maps the underlying [ColumnVector] into a [List] of another type, which
/// can be useful for serialization or formatting to Strings. The subclass
/// can still benefits from strongly typed [ColumnVector] by accepting a
/// type parameter different from T, and perform a cast in the constructor
/// to obtain the [ColumnVector] with exact type.
class IndexedView<T extends Comparable> with ListBase<T?> {
  IndexedView(
    this._index, ColumnVector vector
  ): _vector = vector as SparseVector<T?>;

  final SparseVector<T?> _vector;
  final Index _index;

  @override
  int get length => _index.length;

  @override
  set length(int _) => throw _mutateError;

  @override
  T? operator [](int offset) => access(_vector, _index, offset);

  @override
  void operator []=(int index, T? value) => throw _mutateError;

  static final _mutateError = UnsupportedError("Immutable view");

  @pragma("vm:prefer-inline")
  static T access<T>(
    SparseVector<T> vector, Index index, int offset
  ) => vector[index[offset]];
}

class ComputedView<T extends Comparable> with ListBase<T?> {
  final T? Function(Iterable<Comparable?> sources) compute;
  final List<IndexedView> columns;

  ComputedView(this.columns, this.compute);

  @override
  int get length => columns.first.length;

  @override
  set length(int _) => throw IndexedView._mutateError;

  @override
  T? operator [](int offset) => compute(columns.map((col) => col[offset]));

  @override
  void operator []=(int index, T? value) => throw IndexedView._mutateError;
}

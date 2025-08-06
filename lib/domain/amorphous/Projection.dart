// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../utils/TaggedMultiset.dart';
import 'Index.dart';
import 'IndexedView.dart';
import 'SortedList.dart';
import 'SparseVector.dart';

typedef GenericColumn = SparseVector<Comparable?>;
typedef TypedColumn<T extends Comparable> = SparseVector<T?>;

typedef ColumnSelector = List<T?> Function<T extends Comparable>(String _);

final class AttributeNotFoundException implements Exception {
  AttributeNotFoundException(this.attribute);
  final String attribute;
}

class Projection {
  /// Intended for internal use by [EventManifold]
  Projection(this._columns, this._index, [ List<ListIndex>? indices ]) {
    if(indices != null) _indices.addAll(indices);
  }

  Projection get cleared => Projection(_columns, ListIndex([], ""));

  int get length => _index.length;

  /// If [sort] was called on this Projection, returns the attribute's name
  /// of the most recent [sort] operation and if its sorted in descending
  /// order, otherwise returns null
  (String, bool)? get currentlySortedBy => switch(_index.decay) {
    final ListIndex idx => idx.sorted ? (idx.name, _index is DescIndex) : null,
    _ => null
  };

  /// get the internal index at [row]
  int indexAt(int row) => _index[row];

  /// get the row with the internal index [index]
  int? whereIndexIs(int index) => switch(_index.decay) {
    final ListIndex sorted => SortedList(sorted.index).indexOf(
      index, _getColumnByName(sorted.name).indexedCmp
    ),
    _ => index
  };

  /// Retrieve a column associated with [attribute]
  /// The resultant column is immutable and will NOT reflect the changes in the
  /// source [Projection] e.g. [sort] & [reverse]
  V dissect<T extends Comparable, V extends IndexedView<T>>(
    String attribute,
    V viewCtor(Index i, GenericColumn v)
  ) => viewCtor(_index, _getColumnByName(attribute));

  /// Updates the internal state according to the changes in the source
  /// Meant to be passed to [EventManifold.onChange]
  void notify(Index updates) {
    final prevSize = _index.length;
    if(_index case final ListIndex list) {
      if(!list.sorted) list.append(updates);// Sorted indices are handled below
    } else if(_index case final IotaIndex iota) iota.length += updates.length;
    for(final index in _indices) if(
      _columns[index.name] case GenericColumn col
    ) for(final i in updates) SortedList(index.index).place(i, col.indexedCmp);
    onChange(prevSize);
  }

  void clear() {
    _index = ListIndex([], "");
    _indices.clear();
  }

  void remove(int row) {
    if(_index case final ListIndex list) {
      list.remove(row);
    } else throw UnsupportedError(
      "Only projections with ListIndex support remove operation"
    );
  }

  /// Add entries correspond to [indices] into this Projection
  void include(List<int> indices) => notify(ListIndex(indices, ""));

  /// Reverse the order of entries in this projection
  void reverse() => _index = _index.reversed;

  /// Create a new [Projection] with entries filtered by [filter]
  Projection where(List<int> filter(
    Iterable<int> index,
    ColumnSelector getTypedView
  )) {
    final index = ListIndex([], _index.name);
    final res = Projection(_columns, index, [ index ]);
    onChange = (prevSize) => res.notify(ListIndex(filter(SkippedIndex(
      _index, prevSize
    ), _getColumnOfType), _index.name));
    onChange(0);
    return res;
  }

  Iterable<int> search<T extends Comparable>(String attribute, T val) sync* {
    final col = _getColumnOfType<T>(attribute);
    for(int i = 0; i != _index.length; ++i) if(
      col[_index[i]] == val
    ) yield i;
  }

  /// Sync updates to a non-monitoring child projection
  void sync() {
    final prevSize = _index.length;
    _index = IotaIndex(_columns.values.first.length);
    onChange(prevSize);
  }

  ///
  void sort<T extends Comparable>(String attribute, [
    ListIndex indexCtor(String s, SparseVector<T?> v, Index i) = _createIndex
  ]) => _index = switch(attribute) {
    "" => IotaIndex(_index.length),
    _  => getOrderedIndex(indexCtor, attribute)
  };

  Index getOrderedIndex<T extends Comparable>(ListIndex indexCtor(
    String s, SparseVector<T?> v, Index i
  ), String attribute) {
    if(_indices[attribute] case ListIndex index) if(index.sorted) return index;
    final res = indexCtor(attribute, _getColumnOfType<T>(attribute), _index);
    _indices.add(res);
    return res;
  }

  SparseVector<T?> _getColumnOfType<T extends Comparable>(
    String name
  ) => switch(_columns[name]) {
    SparseVector<T?> col => col,
    null => throw AttributeNotFoundException(name),
    _ => throw TypeError()
  };

  GenericColumn _getColumnByName(String name) => switch(_columns[name]) {
    GenericColumn col => col,
    null => throw AttributeNotFoundException(name),
  };

  static ListIndex _createIndex(
    String name, GenericColumn col, Index ref
  ) => ListIndex.from(ref, name)..sort(col.indexedCmp);

  void Function(int prevSize) onChange = (_) {};

  final _indices = TaggedMultiset<ListIndex>([]);
  final Map<String, GenericColumn> _columns;
  Index _index;
}

extension on SparseVector<Comparable?> {
  int indexedCmp(int lhs, int rhs) => switch(this[lhs]) {
    final Comparable l => this[rhs] != null ? l.compareTo(this[rhs]) : -1,
    null => -1,
  };
}

extension <T extends Index> on Set<T> {
  T? operator [] (String name) => this.lookup(name);
}

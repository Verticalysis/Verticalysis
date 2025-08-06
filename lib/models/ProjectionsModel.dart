// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import '../domain/amorphous/Index.dart';
import '../domain/amorphous/EventManifold.dart';
import '../domain/amorphous/IndexedView.dart';
import '../domain/amorphous/Projection.dart';
import '../domain/schema/AttrType.dart';
import 'FiltersModel.dart';

/// Maintains a stack of [Projection]s, each maps to a [Filter] in the
/// [FiltersModel]. The top of the stack, [current], serves as the data
/// source for the Verticells, and any widgets tracking its states.
///
/// Only notifies listeners when the Projection stack changes. Changes of
/// the number of elements is announced by [onSizeChange]
final class ProjectionsModel extends ChangeNotifier {
  final List<Projection> _projections;
  final String? chronologicallySortedBy;
  final cachedColumns = <String, StringfiedView> {};
  VoidCallback preNotify = () {};

  void Function(int size) onSizeChange = (_) {};

  ProjectionsModel(
    EventManifold origin, this.chronologicallySortedBy
  ): _projections = [ origin.expose(true) ] {
    _projections.last.onChange = _onchange;
  }

  ProjectionsModel.single(
    Projection projection,
  ): _projections = [ projection ], chronologicallySortedBy = null;

  Projection get current => _projections.last;
  int get currentLength => _projections.last.length;

  bool get chronologicallySorted {
    if(chronologicallySortedBy == null) return false;
    if(current.currentlySortedBy case (final ordered, final descending)) {
      if(descending) return false;
      return ordered == chronologicallySortedBy;
    } else return false;
  }

  /// Push a projection created with the filter corresponding to [pred]
  void append(String attribute, Filter filter) {
    final next = _projections.last.where((filter).filter);
    next.onChange = _onchange;
    _projections.add(next);
    cachedColumns.clear();
    preNotify();
    notifyListeners();
  }

  /// Pop [filters.length] + [remove] projections from the end of the stack
  /// and replace (push) with projections created from [filters]
  ///
  /// [remove] defaults to 1 for the case that one filter is removed from the
  /// [FiltersModel]. In this case, [filters] should be the filters following
  /// the removed filter.
  void splice(Iterable<Filter> filters, [ int remove = 1 ]) {
    _projections.length -= (filters.length + remove);
    for(final filter in filters) _projections.add(
      _projections.last.where(filter.filter)
    );
    _projections.last.onChange = _onchange;
    cachedColumns.clear();
    preNotify();
    notifyListeners();
  }

  void sort(String attribute, bool descending) {
    current.sort(attribute);
    if(descending) current.reverse();
    cachedColumns.clear();
    preNotify();
    notifyListeners();
  }

  StringfiedView getColumn(
    String name, AttrType getAttrTypeByName(String name)
  ) => current.dissect(name, _view4type[getAttrTypeByName(name).index])/*switch(cachedColumns[name]) {
    final StringfiedView column => column,
    null => current.dissect(name, _view4type[getAttrTypeByName(name).index])
  }*/;

  void forceUpdate() => notifyListeners();

  IndexedView<int> get scrollReference => chronologicallySorted ?
    current.dissect(chronologicallySortedBy!, IndexedView<int>.new) :
    SizedPhonyView(current.length);

  void _onchange(int _) => onSizeChange(current.length);

  static const _view4type = <StringfiedView Function(Index, ColumnVector)>[
    VoidColumnView.new,
    IntColumnView.new,
    FloatColumnView.new,
    HexColumnView.new,
    StringColumnView.new,
    AbsoluteTimeColumnView.new,
  ];
}

final class SizedPhonyView with ListBase<int?> implements IndexedView<int> {
  SizedPhonyView(this.length);

  @override
  int length;

  @override
  int operator [](int index) => throw UnsupportedError("");

  @override
  void operator []=(int index, int? value) => throw UnsupportedError("");
}

abstract class StringfiedView<
  T extends Comparable
> with ListBase<String?> implements IndexedView<String> {
  StringfiedView(
    this.index, ColumnVector vector
  ): _vector = vector as ColumnVector<T>;

  final ColumnVector<T> _vector;
  final Index index;

  AttrType get attrType;

  IndexedView<T> get typedView => IndexedView(index, _vector);

  @override
  int get length => index.length;

  @override
  set length(int _) => throw _mutateError;

  @override
  String? operator [](int offset) {
    final raw = IndexedView.access(_vector, index, offset);
    if(raw != null) return stringfy(raw);
    return null;
  }

  @override
  void operator []=(int index, String? value) => throw _mutateError;

  String stringfy(T value);

  static final _mutateError = UnsupportedError("Immutable view");
}

final class VoidColumnView extends StringfiedView<int> {
  VoidColumnView(super.index, super.vector);

  @override
  AttrType get attrType => AttrType.ignore;

  @override
  String stringfy(int value) => value.toString();
}

final class IntColumnView extends StringfiedView<int> {
  IntColumnView(super.index, super.vector);

  @override
  AttrType get attrType => AttrType.integer;

  @override
  String stringfy(int value) => value.toString();
}

final class FloatColumnView extends StringfiedView<double> {
  FloatColumnView(super.index, super.vector);

  @override
  AttrType get attrType => AttrType.float;

  @override
  String stringfy(double value) => value.toString();
}

final class HexColumnView extends StringfiedView<int> {
  HexColumnView(super.index, super.vector);

  @override
  AttrType get attrType => AttrType.hex;

  @override
  String stringfy(int value) => "0x${value.toRadixString(16)}";
}


final class StringColumnView extends StringfiedView<String> {
  StringColumnView(super.index, super.vector);

  @override
  AttrType get attrType => AttrType.string;

  @override
  String stringfy(String value) => value;
}

final class AbsoluteTimeColumnView extends StringfiedView<int> {
  AbsoluteTimeColumnView(super.index, super.vector);

  @override
  AttrType get attrType => AttrType.string;

  @override
  String stringfy(int value) => DateTime.fromMicrosecondsSinceEpoch(value).toString();
}

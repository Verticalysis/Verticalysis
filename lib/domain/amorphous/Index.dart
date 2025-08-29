// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

int _asis(int src) => src;

abstract class Index with IterableBase<int> {
  int operator [](int index);
  List<int> where(bool pred(int val));
  String get name;
  Index get decay;
  int get length;

  @override
  bool operator ==(Object other) => switch(other) {
    final Index index => index.name == name,
    _ => false
  };

  @override
  int get hashCode => name.hashCode;

  Index get reversed => switch(this) {
    final DescIndex index => index._underlying,
    _ => DescIndex(this)
  };

  @override
  Iterator<int> get iterator => Iterable<int>.generate(
    length, (i) => this[i]
  ).iterator;
}

final class IotaIndex extends Index {
  int length;

  IotaIndex(this.length);

  @override
  int operator [](int offset) => offset;

  @override
  List<int> where(
    bool Function(int val) pred
  ) => List.generate(length, _asis)..retainWhere(pred);

  @override
  String get name => "";

  @override
  Index get decay => this;
}

final class ListIndex extends Index {
  final List<int> index;
  bool sorted;

  ListIndex(this.index, this._name, [ this.sorted = false ]);

  static ListIndex from(Index src, String name) => switch(src.decay) {
    final IotaIndex iota => ListIndex(List.generate(iota.length, _asis), name),
    final ListIndex list => ListIndex(List.from(list), name, list.sorted),
    _ => throw TypeError()
  };

  void insert(int offset, int val) => index.insert(offset, val);

  void append(Iterable<int> added) => index.addAll(added);

  void remove(int pos) => index.removeAt(pos);

  void sort(int cmp(int lhs, int rhs)) {
    index.sort(cmp);
    sorted = true;
  }

  @override
  int operator [](int offset) => index[offset];

  @override
  List<int> where(bool pred(int val)) => index.where(pred).toList();

  @override
  String get name => _name;

  @override
  Index get decay => this;

  @override
  int get length => index.length;

  final String _name;
}

final class DescIndex extends Index {
  final Index _underlying;

  DescIndex(this._underlying);

  @override
  int operator [](int offset) => _underlying[length - 1 - offset];

  @override
  List<int> where(bool pred(int val)) => _underlying.where(pred);

  @override
  String get name => _underlying.name;

  @override
  Index get decay => _underlying.decay;

  @override
  int get length => _underlying.length;
}

final class SkippedIndex extends Index {
  SkippedIndex(this._underlying, this._offset);

  @override
  int operator [](int offset) => _underlying[offset + _offset];

  @override
  List<int> where(bool pred(int val)) => [ for(
    int i = _offset; i != _underlying.length; ++i
  ) if(pred(_underlying[i])) _underlying[i] ];

  @override
  String get name => _underlying.name;

  @override
  Index get decay => _underlying.decay;

  @override
  int get length => _underlying.length;

  final Index _underlying;
  final int _offset;
}

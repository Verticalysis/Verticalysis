// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

/// A view on [_list] from the [start]th element (inclusive) to the
/// [start] + [length]th element (exclusive)
final class ListView<T> with ListMixin<T> {
  ListView(this._list, this.start, this.length);

  ListView.fromRange(this._list, this.start, int end): length = end - start;

  final List<T> _list;
  final int start;

  @override
  int length;

  @override
  T operator [](int index) => _list[index + start];

  @override
  void operator []=(int index, T value) => _list[index + start] = value;
}

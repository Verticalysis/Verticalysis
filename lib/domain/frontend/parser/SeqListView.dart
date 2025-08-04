// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

/// A flat, immutable view over multiple lists with O(1) random access.
class SeqListView<T> extends ListBase<T> {
  /// Number of bits used to calculate chunk size (2^chunkBits).
  static const int _chunkBits = 2;

  /// Size of each chunk == 1 << _chunkBits.
  @pragma("vm:prefer-inline")
  static int get _chunkSize => 1 << _chunkBits;

  final List<(List<T>, int)> _chunks = [];

  int _length = 0;

  /// Create a view with chunk size = 2^[chunkBits].
  SeqListView(List<T> initial) {
    append(initial);
  }

  SeqListView.Empty();

  /// Append all elements from [list] into the view.
  void append(List<T> list) {
    if (list.isEmpty) return;
    int base = 0;

    // If the last chunk is a partial array-chunk, try to fill it.
    if(_chunks.isNotEmpty){
      final (chunk, _) = _chunks.last;
      if(chunk.length < _chunkSize) {
        int need = _chunkSize - chunk.length;
        int take = (need < list.length) ? need : list.length;
        // Merge old remainder with first [take] elements of new list
        List<T> merged = List<T>.from(chunk);
        merged.addAll(list.sublist(0, take));
        _chunks[_chunks.length - 1] = (merged, 0);
        base += take;
        _length += take;
      }
    }

    while(base < list.length) {
      int remaining = list.length - base;
      if(remaining >= _chunkSize) {
        _chunks.add((list, base));
        base += _chunkSize;
        _length += _chunkSize;
      } else {
        _chunks.add((list.sublist(base), 0));
        _length += remaining;
        break;
      }
    }
  }

  @override
  int get length => _length;

  @override
  set length(int i) => throw UnsupportedError('Cannot modify immutable view');

  @override
  T elementAt(int index) => this[index];

  @override
  T operator [](int index) {
    final chunkIndex = index >> _chunkBits;
    final offset = index & (_chunkSize - 1);
    final (chunk, base) = _chunks[chunkIndex];
    return chunk[base + offset];
  }

  @override
  void operator []=(int index, T value) {
    throw UnsupportedError('Cannot modify immutable view');
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

/// A linear data structure optimized for storing potentially sparse data with
/// high memory efficiency.
final class SparseVector<T> with ListBase<T> implements List<T> {
  SparseVector(T emptyVal, {
    int chunkSizeExp = 6
    }): _emptyChunk = List.filled(1 << chunkSizeExp, emptyVal),
      _chunkSizeExp = chunkSizeExp;

  final List<List<T>> _chunks = [];
  final List<T> _emptyChunk;
  final int _chunkSizeExp;
  int _length = 0;

  int get _chunkSize => 1 << _chunkSizeExp;
  T get _emptyVal => _emptyChunk.first;

  bool isEmptyChunk(int chunk) => _chunks[chunk] == _emptyChunk;

  @override
  int get length => _length;

  @override
  set length(int newLength) {
    final requiredChunks = (newLength + _chunkSize - 1) >> _chunkSizeExp;

    if (newLength < _length) { // Truncate
      final truncatedChunks = (newLength + _chunkSize - 1) >> _chunkSizeExp;
      _chunks.length = truncatedChunks;
    } else if(newLength > _length) { // Extend
      _chunks.addAll(
        Iterable.generate(requiredChunks - _chunks.length, (_) => _emptyChunk),
      );
    }

    _length = newLength;
  }

  @override
  T operator [](int index) {
    final chunk = index >> _chunkSizeExp;
    return _chunks[chunk][_offset(index)];
  }

  @override
  void operator []=(int index, T value) {
    final chunk = index >> _chunkSizeExp;

    if(_chunks[chunk] == _emptyChunk) {
      _chunks[chunk] = List.filled(_chunkSize, _emptyVal);
    }
    _chunks[chunk][_offset(index)] = value;
  }

  @override
  void add(T value) {
    final offset = _offset(_length);

    if(_length == 0 || offset == 0) { // Allocate a new chunk if needed
      _compact();
      _chunks.add(List.filled(_chunkSize, _emptyVal));
    }

    this[_length++] = value;
  }

  @override
  void addAll(Iterable<T> values) {
    for(final val in values) add(val);
  }

  @pragma("vm:prefer-inline")
  int _offset(int index) => index & (_chunkSize - 1);

  void _compact() {
    if(_chunks.isEmpty) return;
    if(_chunks.last.any((e) => e!= _emptyVal)) return;
    _chunks.last = _emptyChunk;
  }
}

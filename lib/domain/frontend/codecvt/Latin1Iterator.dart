// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

/// Iterator which converts ISO/IEC 8859-1 Latin-1 encoded bytes into UTF-16
/// codepoints. Note this implementation does NOT reject undefined codepoints
/// to maximize performance - it acts as a pass-through adapter for faster
/// processing on inputs supposedly to be ASCII or Latin-1 encoded.
final class Latin1Iterator implements Iterator<int> {
  Latin1Iterator(this._data, [int offset = -1]): _offset = offset;
  Latin1Iterator._(): _data = const [], _offset = -1;

  void _set(Iterable<int> data, int offset) {
    _data = data;
    _offset = offset;
  }

  Iterable<int> _data;
  int _offset;

  @override
  @pragma("vm:prefer-inline")
  // As latin-1 encodes Unicode U+0000 to U+00FF directly into a single byte,
  // no conversion is required.
  int get current => _data.elementAt(_offset);

  @override
  bool moveNext() => ++_offset < _data.length;

  @override
  bool operator ==(Object other) => switch(other) {
    final Latin1Iterator iter => iter._data == _data && iter._offset == _offset,
    _ => false
  };

  static Latin1Iterator from(
    Iterable<int> src, [ Iterator<int> dst() = Latin1Iterator._ ]
  ) => switch(src.iterator) {
    final Latin1Iterator iter => (
      dst() as Latin1Iterator
    ).._set(iter._data, iter._offset),
    _ => (dst() as Latin1Iterator).._set(src, -1)
  };
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

/// Iterator which converts ISO/IEC 8859-1 Latin-1 encoded bytes into UTF-16
/// codepoints. Note this implementation does NOT reject undefined codepoints
/// to maximize performance - it acts as a pass-through adapter for faster
/// processing on inputs supposedly to be ASCII or Latin-1 encoded.
class Latin1Iterator implements Iterator<int> {
  Latin1Iterator(this._data, [int offset = -1]): _offset = offset;

  final Iterable<int> _data;
  int _offset;

  @override
  @pragma("vm:prefer-inline")
  // As latin-1 encodes Unicode U+0000 to U+00FF directly into a single byte,
  // no conversion is required.
  int get current => _data.elementAt(_offset);

  @override
  bool moveNext() => ++_offset < _data.length;

  static Latin1Iterator from(Iterable<int> src) => switch(src.iterator) {
    final Latin1Iterator iter => Latin1Iterator(iter._data, iter._offset),
    _ => Latin1Iterator(src)
  };
}

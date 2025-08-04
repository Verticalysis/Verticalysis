// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

/// Iterator which converts RFC-3629 UTF-8 encoded bytes into UTF-16 codepoints
class UTF8Iterator implements Iterator<int> {
  UTF8Iterator(this._data, [
    int offset = 0, int current = -256
  ]): _offset = offset, _current = current;

  final Iterable<int> _data;
  int _offset;
  int _current;

  UTF8Iterator clone() => UTF8Iterator(_data, _offset, _current);

  @override
  int get current => _current;

  @override
  bool moveNext() {
    if(_offset >= _data.length) return false;

    final b0 = _data.elementAt(_offset);
    final prevOffset = _offset;

    if((b0 & 0x80) == 0x00) {
      _current = b0;
      _offset += 1;
    } else if((b0 & 0xE0) == 0xC0) {
      if((_offset += 2) > _data.length) return _incomplete(prevOffset);
      final b1 = _data.elementAt(prevOffset + 1);
      if(_isInvalid(b1)) return _invalid(prevOffset, b0);
      _current = ((b0 & 0x1F) << 6) | (b1 & 0x3F);
    } else if((b0 & 0xF0) == 0xE0) {
      if((_offset += 3) > _data.length) return _incomplete(prevOffset);
      final b1 = _data.elementAt(prevOffset + 1);
      final b2 = _data.elementAt(prevOffset + 2);
      bool invalid = _isInvalid(b1);
      invalid = invalid || _isInvalid(b2);
      if(invalid) return _invalid(prevOffset, b0);
      _current = (b0 & 0x0F) << 12;
      _current |= (b1 & 0x3F) << 6;
      _current |= b2 & 0x3F;
    } else if((b0 & 0xF8) == 0xF0) {
      if((_offset += 4) > _data.length) return _incomplete(prevOffset);
      final b1 = _data.elementAt(prevOffset + 1);
      final b2 = _data.elementAt(prevOffset + 2);
      final b3 = _data.elementAt(prevOffset + 3);
      bool invalid = _isInvalid(b1);
      invalid = invalid || _isInvalid(b2);
      invalid = invalid || _isInvalid(b3);
      if(invalid) return _invalid(prevOffset, b0);
      _current = (b0 & 0x07) << 18;
      _current |= (b1 & 0x3F) << 12;
      _current |= (b2 & 0x3F) << 6;
      _current |= b3 & 0x3F;
    } else {
      _current = b0;
      _offset += 1;
    }
    return true;
  }

  @pragma("vm:prefer-inline")
  bool _incomplete(int offset) {
    _current = -(_data.length - offset);
    return true;
  }

  @pragma("vm:prefer-inline")
  bool _invalid(int prevOffset, int byte) {
    _offset = prevOffset + 1;
    _current = byte;
    return true;
  }

  @pragma("vm:prefer-inline")
  bool _isInvalid(int byte) => (byte & 0xC0) != 0x80;

  static UTF8Iterator from(Iterable<int> src) => switch(src.iterator) {
    final UTF8Iterator iter => iter.clone(),
    _ => UTF8Iterator(src)
  };
}

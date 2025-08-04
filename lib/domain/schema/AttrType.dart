// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../amorphous/Attribute.dart';
import '../utils/ScalarTime.dart';

final class InvalidAttrTypeException implements Exception {
  InvalidAttrTypeException(this.type);
  final String type;
}

enum AttrType<T extends Comparable> {
  ignore(_ignore, "Void"),
  integer(_parseInt, "Int"),
  float(_parseFloat, "Float"),
  hex(_parseHex, "Hex"),
  string(_parseString, "String"),
  absoluteTime(_parseAbsoluteTime, "AbsoluteTime"),
  relativeTime(_parseRelativeTime, "RelativeTime"),
  // ip(),
  ; //glob(_parseString);

  const AttrType(this.from, this.keyword);

  final String keyword;
  final T Function(String src) from;

  Attribute<T> toAphAttr(String name) => Attribute<T>(name);

  bool allowCast<R extends Comparable>() => this is AttrType<R>;

  static int _ignore(String src) => 0;

  static String _parseString(String src) => src;

  static int _parseInt(String src) => int.parse(src);

  static double _parseFloat(String src) => double.parse(src);

  static int _parseHex(String src) => switch(int.tryParse(src, radix: 16)) {
    final int i => i,
    null => int.parse(src)
  };

  static int _parseAbsoluteTime(String src) => switch(
    AbsoluteTime.parse(src.codeUnits.iterator, DateTime.now().year)
  ) {
    AbsoluteTime.incomplete => throw FormatException(),
    AbsoluteTime.invalid => throw FormatException(),
    final AbsoluteTime t => t.usSinceEpoch
  };

  static int _parseRelativeTime(String src) => switch(
    RelativeTime.parse(src.codeUnits.iterator)
  ) {
    RelativeTime.incomplete => throw FormatException(),
    RelativeTime.invalid => throw FormatException(),
    final RelativeTime t => t.us
  };

  static AttrType of(
    String name, AttrType notFound(String name)
  ) => AttrType.values.firstWhere(
    (type) => type.keyword == name, orElse: () => notFound(name)
  );
}

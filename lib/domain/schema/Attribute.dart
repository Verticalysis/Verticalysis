// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'AttrType.dart';

typedef Xformer<T extends Comparable> = T? Function(String? src);

/// A segment in the transform components sequence
abstract class FormatSegment {
  bool append(String src, StringBuffer dst);
  String? transform(String src);
}

class StringSegment extends FormatSegment {
  StringSegment(this.segment);
  final String segment;

  @override
  bool append(String src, StringBuffer dst) {
    dst.write(segment);
    return true;
  }

  @override
  String? transform(String src) => segment;
}

class RegExpSegment extends FormatSegment {
  RegExpSegment(String src): regexp = RegExp(src);
  final RegExp regexp;

  @override
  bool append(String src, StringBuffer dst) {
    final match = regexp.firstMatch(src);
    if(match == null) return false;
    if(match.groupCount == 0) {
      dst.write(src);
    } else _pushCaptures(dst, match);
    return true;
  }

  @override
  String? transform(String src) {
    final match = regexp.firstMatch(src);
    if(match == null) return null;
    if(match.groupCount == 0) return src;
    if(match.groupCount == 1) return match.group(1);
    final res = StringBuffer();
    _pushCaptures(res, match);
    return res.toString();
  }

  void _pushCaptures(StringBuffer res, RegExpMatch match) {
    for(int i = 0; i != match.groupCount; ++i) res.write(match.group(i));
  }
}

final class Attribute<T extends Comparable> {
  final String name;
  final String src;
  final AttrType<T> type;

  final format = <FormatSegment>[];

  T? defVal = null;

  Attribute(this.name, this.src, this.type);

  Attribute.relaxed(String name, String src, AttrType type): this(
    name, src, type as AttrType<T>
  );

  set defValLiteral(String literal) => defVal = type.from(literal);

  bool get nonVoid => type != AttrType.ignore;

  /*Xformer<T> get xformer => format.length > 0 ? switch(T) {
    String => _vecXform ? _assemble :_reshape,
    _ => _vecXform ? _assemble.then(parse) : _reshape.then(parse)
  } : parse;*/

  Xformer<T> get xformer => format.length > 0 ?
    _vecXform ? _assemble.then(parse) : _reshape.then(parse):
    parse;

  bool get _vecXform => format.length > 1;

  String? _assemble(String? src) {
    if(src == null) return null;
    final res = StringBuffer();
    for(final segment in format) if(!segment.append(src, res)) return null;
    return res.toString();
  }

  String? _reshape(String? s) => s == null ? null :format.first.transform(s);

  T? Function(String? src) get parse => (src) {
    if(src == null) return defVal;
    try {
      return type.from(src);
    } on FormatException catch(_) {
      return defVal;
    }
  };

  R genericInvoke2<R, A1, A2>(
    R func<G extends Comparable>(A1 _, A2 _), A1 arg1, A2 arg2
  ) => func<T>(arg1, arg2);

  R genericInvoke3<R, A1, A2, A3>(
    R func<G extends Comparable>(A1 _, A2 _, A3 _), A1 arg1, A2 arg2, A3 arg3
  ) => func<T>(arg1, arg2, arg3);

  R match<R>(List<R> list) => list[type.index];

  @override
  // For heterogeneous lookup by the name in a set
  bool operator ==(Object rhs) => switch(rhs) {
    final Attribute attr => attr.name == name,
    final String rhsName => rhsName == name,
    _ => false
  };

  @override
  // For heterogeneous lookup by the name in a set
  int get hashCode => name.hashCode;
}

extension AttributeFactory on AttrType {
  Attribute createAttribute(
    String name, String src
  ) => _constructors[this.index](name, src, this);

  static const _constructors = <Attribute<Comparable> Function(
    String, String, AttrType
  )>[
    Attribute<int>.relaxed,
    Attribute<int>.relaxed,
    Attribute<double>.relaxed,
    Attribute<int>.relaxed,
    Attribute<String>.relaxed,
    Attribute<int>.relaxed,
    Attribute<int>.relaxed,
  ];
}

extension on String? Function(String? src) {
  T? Function(String? src) then<T> (
    T? from(String? src)
  ) => (src) => from(this(src));
}

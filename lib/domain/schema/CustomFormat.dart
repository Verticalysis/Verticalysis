// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../frontend/parser/Primitives.dart';
export '../frontend/parser/Primitives.dart' show CombinatorialParser;

typedef CapturedMatchers = List<(String, CombinatorialParser)>;

typedef IteratorReplicator = Iterator<int> Function(
  Iterable<int> from, [ Iterator<int> Function() ]
);

final class MissingPropertyException implements Exception {
  const MissingPropertyException(this.property);

  final String property;
}

final class InvalidPropertyException implements Exception {
  InvalidPropertyException(this.property, this.original, [ this.message = "" ]);

  final String property;
  final String original;
  final String message;
}

final class UndefinedMatcherException implements Exception {
  UndefinedMatcherException(this.matcher);

  final String matcher;
}

typedef ParserBuilder = CombinatorialParser Function(
  Map spec,
  CapturedMatchers captures,
  T Function <T>(dynamic _) visit,
  IteratorReplicator replicator,
  bool captured
);

extension type MatcherBuilder(T Function <T>(dynamic _) visit) {
  CombinatorialParser build(
    Map spec,
    CapturedMatchers captures,
    IteratorReplicator create
  ) => _build(spec, captures, create, visit);

  static CombinatorialParser _build(
    Map spec,
    CapturedMatchers captures,
    IteratorReplicator create,
    T visit <T>(dynamic _)
  ) {
    final type = spec["match"];
    if(type == null) throw const MissingPropertyException("match");
    if(matchers[visit<String>(type)] case final ParserBuilder builder) {
      final capture = spec["name"];
      final parser = builder(spec, captures, visit, create, capture != null);
      if(capture != null) captures.add((visit<String>(capture), parser));
      return parser;
    } else throw UndefinedMatcherException(visit<String>(type));
  }

  static CombinatorialParser _buildSequenceMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final children = spec["children"];
    if(children == null) throw const MissingPropertyException("children");
    final consumer = SequenceConsumer(visit<List>(children).map(
      (child) => _build(visit<Map>(child), captures, create, visit)
    ).toList()).consumeSequence;

    final position = captures.length;

    if(!captured) return consumer;

    return (iter, lines, col, fields) {
      final begin = create(IntIterableFacade(iter));
      final result = consumer(iter, lines, col, fields);
      fields[position] = _toString(begin, iter);
      return result;
    };
  }

  static CombinatorialParser _buildOptionalMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final child = spec["child"];
    if(child == null) throw const MissingPropertyException("child");
    final consumer = OptionalConsumer(
      _build(visit<Map>(child), captures, create, visit), create
    ).consumeOptional;

    final position = captures.length;

    if(!captured) return consumer;

    return (iter, lines, col, fields) {
      final begin = create(IntIterableFacade(iter));
      final result = consumer(iter, lines, col, fields);
      fields[position] = _toString(begin, iter);
      return result;
    };
  }

  static CombinatorialParser _buildRestOfTheLineMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final position = captures.length;

    if(!captured) return (
      iter, lines, col, fields
    ) => const RestOfTheLineConsumer().consumeTill(
      iter, lines, col, StringBuffer()
    );

    return (iter, lines, col, fields) {
      final s = StringBuffer();
      final result = const RestOfTheLineConsumer().consumeTill(iter, lines, col, s);
      fields[position] = s.toString();
      return result;
    };
  }

  static CombinatorialParser _buildTillMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final token = spec["token"];
    if(token == null) throw const MissingPropertyException("token");
    final charCode = visit<String>(token).codeUnits;
    if(charCode.length != 1) throw InvalidPropertyException(
      "token", visit<String>(token)
    );

    final position = captures.length;

    if(!captured) return (
      iter, lines, col, fields
    ) => TillConsumer(charCode.first).consumeTill(
      iter, lines, col, StringBuffer()
    );

    return (iter, lines, col, fields) {
      final s = StringBuffer();
      final result = TillConsumer(charCode.first).consumeTill(iter, lines, col, s);
      fields[position] = s.toString();
      return result;
    };
  }

  static CombinatorialParser _buildCharMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final token = spec["token"];
    if(token == null) throw const MissingPropertyException("token");
    final charCode = visit<String>(token).codeUnits;
    if(charCode.length != 1) throw InvalidPropertyException(
      "token", visit<String>(token)
    );

    final position = captures.length;

    if(!captured) return (
      iter, lines, col, fields
    ) => CharConsumer(charCode.first).consumeChar(
      iter, lines, col, StringBuffer()
    );

    return (iter, lines, col, fields) {
      final s = StringBuffer();
      final result = CharConsumer(charCode.first).consumeChar(iter, lines, col, s);
      fields[position] = s.toString();
      return result;
    };
  }

  static CombinatorialParser _buildWhiteSpaceMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final position = captures.length;

    if(!captured) return (
      iter, lines, col, fields
    ) => WhiteSpaceConsumer().consumeTill(iter, lines, col, StringBuffer());

    return (iter, lines, col, fields) {
      final s = StringBuffer();
      final result = WhiteSpaceConsumer().consumeTill(iter, lines, col, s);
      fields[position] = s.toString();
      return result;
    };
  }

  static CombinatorialParser _buildLinebreakMatcher(
    Map spec,
    CapturedMatchers captures,
    T visit <T>(dynamic _),
    IteratorReplicator create,
    bool captured
  ) {
    final position = captures.length;

    if(!captured) return (
      iter, lines, col, fields
    ) => consumeLineBreak(iter, lines, col);

    return (iter, lines, col, fields) {
      final begin = create(IntIterableFacade(iter));
      final result = consumeLineBreak(iter, lines, col);
      fields[position] = _toString(begin, iter);
      return result;
    };
  }

  static String _toString(Iterator<int> begin, Iterator<int> end) {
    final buf = StringBuffer();
    while(!(begin == end)) {
      buf.writeCharCode(begin.current);
      begin.moveNext();
    }

    return buf.toString();
  }

  static const matchers = <String, ParserBuilder>{
    "sequence": _buildSequenceMatcher,
    "optional": _buildOptionalMatcher,
    "restOfTheLine": _buildRestOfTheLineMatcher,
    "whiteSpace": _buildWhiteSpaceMatcher,
    "linebreak": _buildLinebreakMatcher,
    "till": _buildTillMatcher,
    "char": _buildCharMatcher,
  };
}

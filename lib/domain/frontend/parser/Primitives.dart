// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

typedef Consumer = MatchResult Function(
  Iterator<int> iter, int lines, int col, StringBuffer s
);

final class CharConsumer {
  final int _char;

  const CharConsumer(this._char);

  MatchResult consumeChar(Iterator<int> iter, int lines, int col, StringBuffer s) {
    final current = iter.current;
    if(current < 0) return MatchResult.incomplete;
    if(current ==_char) return iter.moveNext() ?
      MatchResult.sizeOf(1) :
      MatchResult.matched_chunkEnd;
    return MatchResult.no_match;
  }
}

mixin ConsumeTill {
  bool predicate(int current);

  MatchResult consumeTill(Iterator<int> iter, int lines, int col, StringBuffer s) {
    for(int size = 0; ; ++size) {
      final current = iter.current;
      if(current < 0) return MatchResult.incomplete;
      if(predicate(current)) return MatchResult.sizeOf(size) ;
      s.writeCharCode(current);
      if(!iter.moveNext()) return MatchResult.incomplete;
    }
  }
}

final class TillConsumer with ConsumeTill {
  final int _terminator;

  const TillConsumer(this._terminator);

  @pragma("vm:prefer-inline")
  bool predicate(int current) => current == _terminator;
}

final class RestOfTheLineConsumer with ConsumeTill {
  const RestOfTheLineConsumer();

  @pragma("vm:prefer-inline")
  bool predicate(int current) => current.isCR || current.isLF;
}

final class WhiteSpaceConsumer with ConsumeTill {
  const WhiteSpaceConsumer();

  @pragma("vm:prefer-inline")
  bool predicate(int current) => !current.isSPorHT;
}

MatchResult consumeLineBreak(Iterator<int> iter, int lines, int col) {
  if(iter.current.isCR) {
    if(!iter.moveNext()) return MatchResult.incomplete;
    if(!iter.current.isLF) throw parseFailure(_wrongCRLF, lines, col);
    return iter.moveNext() ? MatchResult.sizeOf(2) : MatchResult.matched_chunkEnd;
  } else if(iter.current.isLF) return iter.moveNext() ?
    MatchResult.sizeOf(1) :
    MatchResult.matched_chunkEnd;
  return MatchResult.no_match;
}

typedef CombinatorialParser = MatchResult Function(
  Iterator<int> iter, int l, int col, List<String> fields
);

final class SequenceConsumer {
  final Iterable<CombinatorialParser> _sequence;

  const SequenceConsumer(this._sequence);

  MatchResult consumeSequence(Iterator<int> iter, int lines, int col, List<String> fields) {
    final initialCol = col;
    for(final consumer in _sequence) {
      final result = consumer(iter, lines, col, fields);
      if(result.shouldYield) return result;
      col += result.size;
    }

    return MatchResult.sizeOf(col - initialCol);
  }
}

final class OptionalConsumer {
  final CombinatorialParser _child;
  final Iterator<int> Function(Iterable<int> from, [ Iterator<int> Function() ]) _create;

  const OptionalConsumer(this._child, this._create);

  MatchResult consumeOptional(Iterator<int> iter, int lines, int col, List<String> fields) {
    final tmp = _create(IntIterableFacade(iter));
    final result = _child(tmp, lines, col, fields);
    if(result == MatchResult.no_match) return MatchResult.sizeOf(0);
    return result;
  }
}

FormatException parseFailure(
  String reason, int lines, int col
) => FormatException("$reason, line$lines: $col", lines, col);

extension type const MatchResult._(int code) {
  static const matched_continue = MatchResult._(1);  // pattern matched, more bytes to read
  static const matched_chunkEnd = MatchResult._(-1); // pattern matched, stream ends
  static const indefinite = MatchResult._(-2);       // stream ends in the middle of a potential match
  static const incomplete = MatchResult._(-3);       // stream ends in the middle of a potential match
  static const no_match = MatchResult._(-4);         // pattern match failed

  static const bytesRest = MatchResult._(0);

  const MatchResult.sizeOf(int size): code = size;

  bool operator>(MatchResult rhs) => code > rhs.code;
  bool operator<(MatchResult rhs) => code < rhs.code;

  bool get shouldYield => code < 1;
  int get size => code;
}

extension CharCode on int {
  bool get isDot                => this == 0x2E;
  bool get isComma              => this == 0x2C;
  bool get isDoubleQuote        => this == 0x22;
  bool get isCR                 => this == 0x0D;
  bool get isLF                 => this == 0x0A;
  bool get isSPorHT             => this == 0x20 || this == 0x09;
  bool get isLeftCurlyBracket   => this == 0x7B;
  bool get isRightCurlyBracket  => this == 0x7D;
  bool get isLeftSquareBracket  => this == 0x5B;
  bool get isRightSquareBracket => this == 0x5D;
  bool get isBackSlash          => this == 0x5C;
  bool get isHyphen             => this == 0x2D;
}

final class IntIterableFacade extends Iterable<int> {
  IntIterableFacade(this.iterator);

  @override
  final Iterator<int> iterator;
}

const _wrongCRLF = "Unexpected character after CR in line break";

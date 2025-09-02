// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'Primitives.dart';
import 'Quadramaton.dart';

final class FieldParser {
  final int _fieldIndex;
  final Consumer _parseEntry;
  final List<String> _fields;

  const FieldParser(this._parseEntry, this._fieldIndex, this._fields);

  MatchResult call(Iterator<int> iter, int l, int col, ) {
    final buffer = StringBuffer();
    final result = _parseEntry(iter, l, col, buffer);
    _fields[_fieldIndex] = buffer.toString();
    return result;
  }
}

final class Combinatorial {
  final int _fieldsPerEntry;
  final CombinatorialParser _parser;
  final Iterator<int> Function(Iterable<int> from, [ Iterator<int> Function() ]) _create;

  static const _failMsg = "Top-level pattern match failed";

  /// Construct a Combinatorial parser accepting a stream of raw bytes
  const Combinatorial(this._create, this._parser, this._fieldsPerEntry);

  Stream<List<List<String>>> parse(Stream<List<int>> src, [
    List<List<String>> commitQueueCtor() = Quadramaton.commitQueueCtor
  ]) => Quadramaton(_create).parse(src, parseEntry, commitQueueCtor);

  State parseEntry(Iterator<int> iter, List<String> fields, int lines) {
    fields..addAll(Iterable.generate(_fieldsPerEntry, (_) => ""));
    final result = _parser(iter, lines, 1, fields);
    return switch(result) {
       MatchResult.indefinite => State.incomplete,
       MatchResult.incomplete => State.incomplete,
      > MatchResult.bytesRest => State.endOfEntry,
      < MatchResult.bytesRest => State.endOfChunk,
      MatchResult.no_match => throw parseFailure(_failMsg, lines, result.size),
      _ => throw StateError("unreachable")
    };
  }
}

MatchResult phonyCombinatorialParser(
  Iterator<int> iter, int l, int col, List<String> fields
) => MatchResult.sizeOf(0);

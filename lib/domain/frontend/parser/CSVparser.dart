// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'Quadramaton.dart';

// There are three cases when the indefinite state is reached:
// 1. This chunk is the last chunk of bytes, hence the line break is omitted
//    for the last field in the last line.
// 2. This chunk is not the last chunk of bytes. For unquoted fields, this
//    either means there are more contens in the field, or there is an end
//    of field indicator at the start of the next chunk of bytes. For quoted
//    fields, this can only happen when the end of field indicator is not seen
//    after the right quote, leaving it as the last byte in the chunk. If the
//    chunk ends before the right quote, move to the incomplete state instead.
// 3. This chunk is not the last chunk of bytes, but the Stream of byte chunks
//    ends unexpectedly due to some error. Handling of this case is out of the
//    scope of this library.
//
// There are two cases when the incomplete state is reached:
// 1. A code point consists of 1+ bytes was broken into two at the boundary
//    of two two chunks
// 2. There are more contents in the field (including the right quote).
//
// The boundary of the content can only be determined on a quoted field before
// a delimiter is encountered. Therefore, the second case can only happen when
// parsing a quoted field.
//
// When there are more chunks in the stream, for both indefinite state and
// incomplete state, work on the potentially incomplete line is discarded, and
// the process restarts from the start of the the incomplete line in the middle
// of the corresponding chunk, with the later chunks appended. The handling of
// these two states only differs at the end of stream. When we reach the end of
// stream in incomplete state, an error is raised and the work of that line is
// discarded. For indefinite state, the result on the potentially incomplete
// line is accepted without checking, since we are not tracking the number of
// fields in a line and there's no way to tell if that line is indeed cut in
// the middle.
//

extension type const MatchResult._(int code) {
  // pattern matched, more bytes to read
  static const matched_continue = MatchResult._(1);
  // pattern matched, stream ends
  static const matched_chunkEnd = MatchResult._(-1);
  // stream ends in the middle of a potential match
  static const insufficient = MatchResult._(-2);
  // pattern match failed
  static const no_match = MatchResult._(0);

  static const bytesRest = MatchResult._(0);

  const MatchResult.sizeOf(int size): code = size;

  bool operator>(MatchResult rhs) => code > rhs.code;
  bool operator<(MatchResult rhs) => code < rhs.code;

  int get size => code;
}

/// Construct a CSV parser accepting a stream of raw bytes
///
/// Note that this implementation does not fully conform to RFC-4180. Most
/// notably, it is more permissive in many cases where the input should be
/// rejected as invalid according to the original specification e.g. records
/// with different number of fields, unquoted fileds with double quotes in the
/// middle, etc.
///
/// The raw bytes are decoded into Unicode char codes with an iterator
/// returned by [create]. The iterator is either created from a Iterable<int>
/// casted from any container, or an iterator of its own type wrapped by an
/// Iterable<int>. In the later case, [create] should return a copy of the
/// iterator passed to it. This means the state of the returned iterator is
/// not affected by calling [Iterator.moveNext] on the original iterator.
/// When a code point consists of multiple bytes and the source iterator
/// reaches the end before all bytes of that code point are collected,
/// [Iterator.current] should yield a negative number, and return false for
/// the next call to [Iterator.moveNext].
extension type CSVparser(Iterator<int> Function(Iterable<int> from) create) {
  /// Parses a CSV String encoded as a [Stream] of [List]<int> with arbitrary
  /// encoding into [List]<String>s. A single row is represented as a [List] of
  /// [String]. All rows can be parsed in a conversion are packed together
  /// as a single event in the resultant [Stream]. Number of fields in a row
  /// is unchecked. This means rows with different fields are not considered
  /// as an error, even though this is against the specification of RFC-4180.
  Stream<List<List<String>>> parse(Stream<List<int>> src, [
    List<List<String>> commitQueueCtor() = Quadramaton.commitQueueCtor
  ]) => Quadramaton(create).parse(src, parseEntry, commitQueueCtor);

  static State parseEntry(Iterator<int> iter, List<String> fields, int lines) {
    final buffer = StringBuffer();
    int col = 1;
    while(true) {
      buffer.clear();
      final result = consumeField(iter, lines, col, buffer);
      col += result.size;
      // flush in case this is indeed the last entry
      if(result == MatchResult.matched_chunkEnd) {
        fields.add(buffer.toString()); // if it's not, [fields] is discarded
        return State.indefinite;
      } else if(result == MatchResult.insufficient) return State.incomplete;
      fields.add(buffer.toString());
      final delim = consumeDelimiter(iter);
      if(delim == MatchResult.matched_continue) {
        ++col;
      } else if(delim == MatchResult.matched_chunkEnd) {
        fields.add(""); // Trailing comma indicates an empty field at the tail
        return State.indefinite;
      } else /* result == 0 */ switch(consumeLineBreak(iter, lines, col)) {
        case MatchResult.no_match: throw parseFailure(_unterminatedLine, lines, col);
        case MatchResult.insufficient: return State.incomplete;
        case > MatchResult.bytesRest: return State.endOfEntry;
        case < MatchResult.bytesRest: return State.endOfChunk;
      }
    }
  }

  static MatchResult consumeDelimiter(Iterator<int> iter) {
    if(iter.current.isComma) return iter.moveNext() ?
      MatchResult.matched_continue :
      MatchResult.matched_chunkEnd;
    return MatchResult.no_match;
  }

  static MatchResult consumeLineBreak(Iterator<int> iter, int lines, int col) {
    if(iter.current.isCR) {
      if(!iter.moveNext()) return MatchResult.insufficient;
      if(!iter.current.isLF) throw parseFailure(_wrongCRLF, lines, col);
      return iter.moveNext() ? MatchResult.matched_continue : MatchResult.matched_chunkEnd;
    } else if(iter.current.isLF) return iter.moveNext() ?
      MatchResult.matched_continue :
      MatchResult.matched_chunkEnd;
    return MatchResult.no_match;
  }

  static MatchResult consumeField(
    Iterator<int> iter, int line, int col, StringBuffer s
  ) => iter.current.isDoubleQuote ? consumeQuotedField(
    iter, line, col, s
  ) : consumeSimpleField(iter, s);

  static MatchResult consumeSimpleField(Iterator<int> iter, StringBuffer s) {
    for(int size = 0; ; ++size) {
      if(iter.current < 0) return MatchResult.insufficient;
      if(fieldEndsHere(iter)) return MatchResult.sizeOf(size);
      s.writeCharCode(iter.current);
      if(!iter.moveNext()) break;
    }
    return MatchResult.matched_chunkEnd;
  }

  static MatchResult consumeQuotedField(
    Iterator<int> iter, int line, int col, StringBuffer buffer
  ) {
    bool pendingEscape = false;
    for(int size = 0; iter.moveNext(); ++size) if(iter.current < 0) {
      break;
    } else if(pendingEscape) {
      if(iter.current.isDoubleQuote) { // escaped dquotes
        pendingEscape = false;
        buffer.write("\"");
        continue;
      } else if(fieldEndsHere(iter)) return MatchResult.sizeOf(size); // closing dquotes
      throw parseFailure(_unescapedDquotes, line, col + size);
    } else if(iter.current.isDoubleQuote) {
      pendingEscape = true; // possible for escaping, don't write immediately
    } else buffer.writeCharCode(iter.current);
    if(pendingEscape) return MatchResult.matched_chunkEnd;
    return MatchResult.insufficient;
  }

  static bool fieldEndsHere(
    Iterator<int> iter
  ) => iter.current.isComma || iter.current.isCR || iter.current.isLF;

  static FormatException parseFailure(
    String reason, int lines, int col
  ) => FormatException("$reason, line$lines: $col", lines, col);

  static const _wrongCRLF = "Unexpected character after CR in line break";
  static const _unescapedDquotes = "Unescaped double quotes in the field";
  static const _unterminatedLine = "Line break not found at the end of a row";
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'SeqListView.dart';

enum State {
  endOfEntry,  // Last line with line break processed, more in chunk
  endOfChunk,  // Last line with line break processed, end of chunk
  incomplete,  // Last line cuts in the middle, results discarded
  indefinite,  // Last line processed, line break unseen
}

// Quadramaton maintains two buffers: the append buffer and the commit buffer.
// The parsed pieces of the entry being processed are first written to the
// append buffer, and flushed into the commit buffer when the entire entry is
// processed. When the end of the current chunk is reached, all entries in the
// commit buffer are flushed into the resultant stream.
//
// As boundaries of entries may not always (or hardly ever in most cases) align
// with the start and the end of chunks, at times the operation of the parser
// needs to be suspended and resumed in the middle of an entry. This is where a
// key difference between Quadramaton and other stream-oriented parsers arises:
// Instead of tracking the exact position and internal state when the operation
// is suspended and resumed, Quadramaton simply starts over at the beginning
// of the chopped entry when the next chunk arrives, and the partial work in
// append buffer is discarded. This grants Quadramaton a clear operation model
// with only 4 generic states, however intricate the format being parsed is.
//
extension type Quadramaton(Iterator<int> Function(Iterable<int> from) create) {
  static const _incompleteStream = "Stream ends unexpectedly.";

  /// To reduce allocations, an external commit buffer can be supplied with
  /// [commitQueueCtor]. It can always return the same list as long as the
  /// contents are consumed each time a new event is emitted.
  Stream<List<List<String>>> parse(Stream<List<int>> src, State parseEntry(
    Iterator<int> iter, List<String> fields, int lines
  ), [ List<List<String>> commitQueueCtor() = commitQueueCtor ]) async* {
    State state = State.endOfChunk;
    int lines = 1;
    SeqListView<int> prevBytes = SeqListView.Empty();
    List<String> append = [];
    List<List<String>> commit = commitQueueCtor();
    Iterator<int> decoder = create(const <int>[]);
    await for(final bytes in src) try {
      if(state == State.endOfChunk) {
        prevBytes = SeqListView.Empty();
        final incoming = create(prevBytes..append(bytes));
        if(!incoming.moveNext()) continue;
        decoder = incoming;
      } else prevBytes.append(bytes);
      Iterator<int> ckpt = create(decoder.iterable);
      append = <String>[];
      forEachEntry:
      while(true) switch(parseEntry(decoder, append, lines)) {
        case State.endOfEntry:
          ++lines;
          commit.add(append);
          ckpt = create(decoder.iterable);
          append = <String>[];
          state = State.endOfEntry;
        case State.endOfChunk:
          ++lines;
          commit.add(append);
          yield commit;
          commit = commitQueueCtor();
          state = State.endOfChunk;
          break forEachEntry;
        case State.indefinite:
          decoder = ckpt;
          state = State.indefinite;
          yield commit;
          commit = commitQueueCtor();
          break forEachEntry;
        case State.incomplete:
          decoder = ckpt;
          state = State.incomplete;
          yield commit;
          commit = commitQueueCtor();
          break forEachEntry;
      }
    } on FormatException catch(e) {
      yield* Stream.error(e);
      return;
    }
    if(state == State.incomplete) {
      yield* Stream.error(FormatException(_incompleteStream));
    } else if(state == State.indefinite) yield [ append ];
  }

  static List<List<String>> commitQueueCtor() => List<List<String>>.empty(
    growable: true
  );
}

class IterableFacade<T> extends Iterable<T> {
  IterableFacade(this.iterator);

  @override
  final Iterator<T> iterator;
}

extension <T> on Iterator<T> {
  Iterable<T> get iterable => IterableFacade(this);
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

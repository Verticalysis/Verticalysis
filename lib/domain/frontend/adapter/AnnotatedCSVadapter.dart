// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../schema/Attribute.dart';
import '../Types.dart';

final class MissingAttributeException implements Exception {
  MissingAttributeException(Attribute attr): attribute = attr.name;
  final String attribute;
}

extension type AnnotatedCSVadapter(Iterable<Attribute> attrs) {
  ChunkedStream<List<String>> transform(ChunkedStream<List<String>> src) async* {
    final reorderBuf = List<String>.filled(attrs.length, "");
    final reorderSrc = <int>[];
    bool firstChunk = true;
    await for(final chunk in src) {
      if(firstChunk) {
        final header = chunk.first;
        for(final attribute in attrs) if(header.indexOf(
          attribute.src
        ) case final i && != -1) {
          reorderSrc.add(i);
        } else throw MissingAttributeException(attribute);
        chunk.removeAt(0);
        firstChunk = false;
      }
      for(final entry in chunk) {
        int current = 0;
        for(final index in reorderSrc) reorderBuf[current++] = entry[index];
        entry.replaceRange(0, reorderBuf.length, reorderBuf);
      }
      yield chunk;
    }
  }
}

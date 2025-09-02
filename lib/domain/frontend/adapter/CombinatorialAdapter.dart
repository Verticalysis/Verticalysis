// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../schema/Schema.dart';
import '../Types.dart';

extension type CombinatorialAdapter(CustomSchema schema) {
  ChunkedStream<List<String>> transform(ChunkedStream<List<String>> src) async* {
    final reorderBuf = List<String>.filled(schema.customFormatCaptures.length, "");
    final reorderSrc = <int>[];
    for(final attribute in schema.attributes) if(
      schema.customFormatCaptures.indexWhere((capture) {
        final (name, _) = capture;
        return name == attribute.src;
      }) case final i && != -1
    ) reorderSrc.add(i);

    await for(final chunk in src) {
      for(final entry in chunk) {
        int current = 0;
        for(final index in reorderSrc) reorderBuf[current++] = entry[index];
        entry.replaceRange(0, reorderBuf.length, reorderBuf);
      }
      yield chunk;
    }
  }
}

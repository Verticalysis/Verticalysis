// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../Types.dart';

extension TransposeCSV on ChunkedStream<List<String>> {
  Stream<IntakeChunk<String>> transpose() async*{
    bool firstChunk = true;
    List<String> attributes = const <String>[];
    await for(final chunk in this) {
      if(firstChunk) {
        attributes = chunk.first;
        chunk.removeAt(0);
        firstChunk = false;
      }
      int i = -1;
      yield (attributes.map((attribute) {
        ++i;
        return (attribute, chunk.map((entry) => entry.elementAtOrNull(i)));
      }), chunk.length);
    }
  }
}

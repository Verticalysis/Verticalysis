// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../utils/ListView.dart';

extension type Framer(int size) {
  Stream<ListView<T>> process<T>(
    Stream<List<T>> src
  ) => src.expand((lst) => [
    for(int i = 0; i < lst.length; i += size) ListView(
      lst, i, i + size < lst.length ? size : lst.length - i
    )
  ]);
}

extension RedirToFramer<T> on Stream<List<T>> {
  Stream<ListView<T>> operator >> (Framer framer) => framer.process(this);
}

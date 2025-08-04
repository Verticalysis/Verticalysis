// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../schema/Attribute.dart';
import '../Types.dart';

extension type CSVadapter(Iterable<Attribute> attrs) {
  ChunkedStream<List<String>> transform(ChunkedStream<List<String>> src) {
    return src;
  }
}

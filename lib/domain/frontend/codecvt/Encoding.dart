// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'Latin1Iterator.dart';
import 'UTF8Iterator.dart';

typedef Decoder = Iterator<int>;

enum Encoding {
  latin1(Latin1Iterator.from),
  utf8(UTF8Iterator.from);

  const Encoding(this.decoder);

  final Decoder Function(Iterable<int> data) decoder;

  static Encoding of({
    required String name,
    required Encoding notFound(String name)
  }) => Encoding.values.firstWhere(
    (enc) => enc.name == name, orElse: () => notFound(name)
  );
}

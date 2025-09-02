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

  final Decoder Function(Iterable<int> data, [Decoder Function()]) decoder;

  /*R genericInvoke3<R, A1, A2, A3>(
    R func<G extends Iterator<int>>(A1 _, A2 _, A3 _), A1 arg1, A2 arg2, A3 arg3
  ) => func<T>(arg1, arg2, arg3);*/

  static Encoding of({
    required String name,
    required Encoding notFound(String name)
  }) => Encoding.values.firstWhere(
    (enc) => enc.name == name, orElse: () => notFound(name)
  );
}

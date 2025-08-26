// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

Iterable<(T1, T2)> zip2<T1, T2>(Iterable<T1> i1, Iterable<T2> i2) sync* {
  final (iter1, iter2) = (i1.iterator, i2.iterator);
  while(iter1.moveNext()) {
    iter2.moveNext();
    yield (iter1.current, iter2.current);
  }
}

Iterable<(T1, T2, T3)> zip3<T1, T2, T3>(
  Iterable<T1> i1, Iterable<T2> i2, Iterable<T3> i3
) sync* {
  final (iter1, iter2, iter3) = (i1.iterator, i2.iterator, i3.iterator);
  while(iter1.moveNext()) {
    iter2.moveNext();
    iter3.moveNext();
    yield (iter1.current, iter2.current, iter3.current);
  }
}

extension Equals <T> on Iterable<T> {
  bool equals(Iterable<T> rhs) => zip2(this, rhs).every((pair) {
    final (lhs, rhs) = pair;
    return lhs == rhs;
  });
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'SparseVector.dart';

final class Attribute<T extends Comparable> {
  const Attribute(this.name);

  final String name;
  SparseVector<T?> allocVector(int size) => SparseVector(null)..length = size;

  @override
  bool operator ==(Object other) => switch(other) {
    final String rhs => rhs == name,
    final Attribute attribute => attribute.name == name,
    _ => false
  };

  @override
  int get hashCode => name.hashCode;

  static const defaultAttr = Attribute<String>("");
}

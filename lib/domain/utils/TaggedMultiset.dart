// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

/// A set with heterogeneous lookup by tag operation
///
/// This class exposes a [Set]-compatible interface but can act as an
/// associative container
///
/// Uses an unsorted list to store all elements. Works well for a small number
/// of elements.
final class TaggedMultiset<T> with SetBase<T> {
  const TaggedMultiset(this._elements);

  final List<T> _elements;

  /// find all
  Iterable<T> findAll(Object tag) {
    final hashcode = tag.hashCode;
    return _elements.where((e) => e.hashCode == hashcode && e == tag);
  }

  @override
  Iterator<T> get iterator => _elements.iterator;

  @override
  int get length => _elements.length;

  @override
  Set<T> toSet() => Set.of(_elements);

  @override
  bool add(T value) {
    if(contains(value)) return false;
    _elements.add(value);
    return true;
  }

  @override
  bool contains(Object? element) {
    final hashcode = element.hashCode;
    return _elements.any((e) => e.hashCode == hashcode && e == element);
  }

  @override
  T? lookup(Object? element) {
    if(element == null) return null;
    final hashcode = element.hashCode;
    return switch(_elements.indexWhere(
      (e) => e.hashCode == hashcode && e == element
    )) {
      -1 => null,
      final int i => _elements[i]
    };
  }

  @override
  bool remove(Object? value) {
    if(value == null) return false;
    final hashcode = value.hashCode;
    final toRemove = _elements.indexWhere(
      (e) => e.hashCode == hashcode && e == value
    );
    if(toRemove == -1) return false;
    _elements.removeAt(toRemove);
    return true;
  }
}

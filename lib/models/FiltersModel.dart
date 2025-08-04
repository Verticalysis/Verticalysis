// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/foundation.dart';

abstract class Filter<T extends Comparable> {
  Filter(this.attribute);

  final String attribute;

  bool Function(T? val) get predicate;
  String get label;
}

final class EqualityFilter<T extends Comparable> extends Filter<T> {
  EqualityFilter(super.attribute, T lhs): predicate = (
    (rhs) => lhs == rhs
  ), label = "$attribute: $lhs";

  static EqualityFilter<T> relaxed<T extends Comparable>(
    String attribute, Comparable lhs
  )=> EqualityFilter<T>(attribute, lhs as T);

  @override
  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class MemberOfFilter<T extends Comparable> extends Filter<T> {
  MemberOfFilter(super.attribute, List<T> set): predicate = (
    (val) => set.contains(val)
  ), label = "$attribute∈ {${set.join(" ")}}";

  @override
  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class IntervalFilter<T extends Comparable> extends Filter<T> {
  IntervalFilter(super.attribute, T min, T max, [
    bool linclusive = true, bool rinclusive = false
  ]): predicate = switch((linclusive, rinclusive)) {
    (true, true)   => (val) => val != null && val >= min && val <= max,
    (true, false)  => (val) => val != null && val >= min && val < max,
    (false, true)  => (val) => val != null && val > min && val <= max,
    (false, false) => (val) => val != null && val > min && val < max,
  }, label = switch((linclusive, rinclusive)) {
    (true, true)   => "$attribute∈ [$min, $max]",
    (true, false)  => "$attribute∈ [$min, $max)",
    (false, true)  => "$attribute∈ ($min, $max]",
    (false, false) => "$attribute∈ ($min, $max)",
  };

  IntervalFilter.relaxedNonInclusive(
    String attribute, Comparable min, Comparable max
  ): this(attribute, min as T, max as T, false, false);

  IntervalFilter.relaxedBothInclusive(
    String attribute, Comparable min, Comparable max
  ): this(attribute, min as T, max as T, true, true);

  IntervalFilter.relaxedLeftInclusive(
    String attribute, Comparable min, Comparable max
  ): this(attribute, min as T, max as T, true, false);

  IntervalFilter.relaxedRightInclusive(
    String attribute, Comparable min, Comparable max
  ): this(attribute, min as T, max as T, false, true);

  @override
  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class LessThanFilter<T extends Comparable> extends Filter<T> {
  LessThanFilter(super.attribute, T max, bool inclusive): predicate = (
    inclusive ? (val) => val != null && val <= max
      : (val) => val != null && val < max
  ), label = inclusive ? "$attribute ≤ $max" : "$attribute < $max";

  LessThanFilter.relaxedInclusive(
    String attribute, Comparable max
  ): this(attribute, max as T, true);

  LessThanFilter.relaxedNonInclusive(
    String attribute, Comparable max
  ): this(attribute, max as T, false);

  @override
  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class GreaterThanFilter<T extends Comparable> extends Filter<T> {
  GreaterThanFilter(super.attribute, T min, bool inclusive): predicate = (
    inclusive ? (val) => val != null && val >= min
      : (val) => val != null && val > min
  ), label = inclusive ? "$attribute ≥ $min" : "$attribute > $min";

  GreaterThanFilter.relaxedInclusive(
    String attribute, Comparable min
  ): this(attribute, min as T, true);

  GreaterThanFilter.relaxedNonInclusive(
    String attribute, Comparable min
  ): this(attribute, min as T, false);

  @override
  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class FiltersModel extends ChangeNotifier {
  final filters = <Filter>[];

  void Function(Iterable<Filter> trailing) onRemove = (_) {};

  bool get isEmpty => filters.isEmpty;

  void clear() {
    filters.clear();
    notifyListeners();
  }

  void append(String column, Filter rule) {
    filters.add(rule);
    notifyListeners();
  }

  Iterable<Filter> remove(int index) {
    filters.removeAt(index);
    notifyListeners();
    onRemove(filters.skip(index));
    return filters.skip(index);
  }
}

extension <T> on Comparable<T> {
  bool operator <=(T other) => this.compareTo(other) <= 0;
  bool operator >=(T other) => this.compareTo(other) >= 0;
  bool operator <(T other) => this.compareTo(other) < 0;
  bool operator >(T other) => this.compareTo(other) > 0;
}

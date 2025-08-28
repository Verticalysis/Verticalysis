// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

abstract class Filter<T extends Comparable> {
  List<int> filter(
    Iterable<int> index,
    List<V?> getTypedView<V extends Comparable>(String name)
  );

  String get label;
}

mixin SingleAttributeFilter<T extends Comparable> implements Filter<T> {
  bool Function(T? val) get predicate;
  String get attribute;

  @override
  List<int> filter(
    Iterable<int> index,
    List<V?> getTypedView<V extends Comparable>(String name)
  ) {
    final view = getTypedView<T>(attribute);
    return index.where((i) => predicate(view[i])).toList();
  }
}

final class EqualityFilter<T extends Comparable>
  extends Filter<T> with SingleAttributeFilter<T> {
  EqualityFilter(this.attribute, T lhs): predicate = (
    (rhs) => lhs == rhs
  ), label = "$attribute: $lhs";

  static EqualityFilter<T> relaxed<T extends Comparable>(
    String attribute, Comparable lhs
  )=> EqualityFilter<T>(attribute, lhs as T);

  final String attribute;

  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class MemberOfFilter<T extends Comparable>
  extends Filter<T> with SingleAttributeFilter<T> {
  MemberOfFilter(this.attribute, List<T> set): predicate = (
    (val) => set.contains(val)
  ), label = "$attribute ∈ { ${set.join(", ")} }";

  static MemberOfFilter<T> relaxed<T extends Comparable>(
    String attribute, List<Comparable?> set
  )=> MemberOfFilter<T>(attribute, set.cast<T>());

  final String attribute;

  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class IntervalFilter<T extends Comparable>
  extends Filter<T> with SingleAttributeFilter<T> {
  IntervalFilter(this.attribute, T min, T max, [
    bool linclusive = true, bool rinclusive = false
  ]): predicate = switch((linclusive, rinclusive)) {
    (true, true)   => (val) => val != null && val >= min && val <= max,
    (true, false)  => (val) => val != null && val >= min && val < max,
    (false, true)  => (val) => val != null && val > min && val <= max,
    (false, false) => (val) => val != null && val > min && val < max,
  }, label = switch((linclusive, rinclusive)) {
    (true, true)   => "$attribute ∈ [$min, $max]",
    (true, false)  => "$attribute ∈ [$min, $max)",
    (false, true)  => "$attribute ∈ ($min, $max]",
    (false, false) => "$attribute ∈ ($min, $max)",
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

  final String attribute;

  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class LessThanFilter<T extends Comparable>
  extends Filter<T> with SingleAttributeFilter<T> {
  LessThanFilter(this.attribute, T max, bool inclusive): predicate = (
    inclusive ? (val) => val != null && val <= max
      : (val) => val != null && val < max
  ), label = inclusive ? "$attribute ≤ $max" : "$attribute < $max";

  LessThanFilter.relaxedInclusive(
    String attribute, Comparable max
  ): this(attribute, max as T, true);

  LessThanFilter.relaxedNonInclusive(
    String attribute, Comparable max
  ): this(attribute, max as T, false);

  final String attribute;

  final bool Function(T? val) predicate;

  @override
  final String label;
}

final class GreaterThanFilter<T extends Comparable>
  extends Filter<T> with SingleAttributeFilter<T> {
  GreaterThanFilter(this.attribute, T min, bool inclusive): predicate = (
    inclusive ? (val) => val != null && val >= min
      : (val) => val != null && val > min
  ), label = inclusive ? "$attribute ≥ $min" : "$attribute > $min";

  GreaterThanFilter.relaxedInclusive(
    String attribute, Comparable min
  ): this(attribute, min as T, true);

  GreaterThanFilter.relaxedNonInclusive(
    String attribute, Comparable min
  ): this(attribute, min as T, false);

  final String attribute;

  final bool Function(T? val) predicate;

  @override
  final String label;
}

mixin FiltersModel {
  final filters = <Filter>[];

  bool get isFiltersEmpty => filters.isEmpty;

  notifyListeners();

  void clearFilters() {
    filters.clear();
    notifyListeners();
  }

  void appendFilter(Filter rule) {
    filters.add(rule);
    notifyListeners();
  }

  Iterable<Filter> removeFilter(int index) {
    filters.removeAt(index);
    notifyListeners();
    return filters.skip(index);
  }
}

extension <T> on Comparable<T> {
  bool operator <=(T other) => this.compareTo(other) <= 0;
  bool operator >=(T other) => this.compareTo(other) >= 0;
  bool operator <(T other) => this.compareTo(other) < 0;
  bool operator >(T other) => this.compareTo(other) > 0;
}

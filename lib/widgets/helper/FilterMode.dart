// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../domain/schema/Attribute.dart';
import '../../models/FiltersModel.dart';

enum FilterMode {
  equality("=", "value...", buildEqualityFilter),
  // memberOf(),
  interval("∈", "[min, max)", buildIntervalFilter),
  lessThan("<", "max value", buildLessThanFilter),
  greaterThan(">", "min value", buildGreaterThanFilter),
  noMoreThan("≤", "max value", buildLessOrEqualFilter),
  noLessThan("≥", "min value", buildLessOrEqualFilter);

  const FilterMode(this.label, this.hint, this.buildFilter);

  final Filter? Function(String literal, Attribute attr) buildFilter;
  final String label;
  final String hint;

  static Filter? buildEqualityFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      EqualityFilter.relaxed, attr.name, value
    )
  };

  static Filter? buildIntervalFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  /*static Filter? buildIntervalFilterNonInclusive(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static Filter? buildIntervalFilterBothInclusive(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static Filter? buildIntervalFilterLeftInclusive(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static Filter? buildIntervalFilterRightInclusive(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };*/

  static Filter? buildLessThanFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static Filter? buildGreaterThanFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      GreaterThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static Filter? buildLessOrEqualFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedInclusive, attr.name, value
    )
  };

  static Filter? buildGreaterOrEqualFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      GreaterThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static const _scalarParser = <Comparable? Function(String)>[
    int.tryParse,
    int.tryParse,
    double.tryParse,
    int.tryParse,
    _identityString,
    int.tryParse,
    int.tryParse,
  ];

  static String _identityString(String s) => s;
}
/*
extension on Comparable? Function(String) {
  (Comparable, Comparable)? parseInterval(literal)
}*/

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../domain/schema/Attribute.dart';
import '../../domain/utils/ScalarTime.dart';
import '../../models/FiltersModel.dart';

typedef ScalarParser = Comparable? Function(String);

enum FilterMode {
  equality("=", "value...", buildEqualityFilter),
  matchAny("∈", "[min, max)", buildMatchAnyFilter),
  lessThan("<", "max value", buildLessThanFilter),
  greaterThan(">", "min value", buildGreaterThanFilter),
  noMoreThan("≤", "max value", buildLessOrEqualFilter),
  noLessThan("≥", "min value", buildLessOrEqualFilter);

  const FilterMode(this.label, this.hint, this.buildFilter);

  final SingleAttributeFilter? Function(
    String literal, Attribute attr
  ) buildFilter;
  final String label;
  final String hint;

  static SingleAttributeFilter? buildEqualityFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      EqualityFilter.relaxed, attr.name, value
    )
  };

  static SingleAttributeFilter? buildMatchAnyFilter(
    String literal, Attribute attr
  ) {
    if(attr is Attribute<String>) {
      return MemberOfFilter<String>(attr.name, _parseCommaSeparatedLiterals(literal));
    } else {
      IntervalFilter? Function<T extends Comparable>(
        String _, Comparable _, Comparable _
      ) filterCtor;
      final scalarParser = attr.match(_scalarParser);
      if(RegExp(r'^\[.*\]$').hasMatch(literal)) {
        filterCtor = IntervalFilter.relaxedBothInclusive;
      } else if(RegExp(r'^\[.*\)$').hasMatch(literal)) {
        filterCtor = IntervalFilter.relaxedLeftInclusive;
      } else if(RegExp(r'^\(.*\]$').hasMatch(literal)) {
        filterCtor = IntervalFilter.relaxedRightInclusive;
      } else if(RegExp(r'^\(.*\)$').hasMatch(literal)) {
        filterCtor = IntervalFilter.relaxedNonInclusive;
      } else { // early return for comma separated literals
        final candidates = _parseCommaSeparatedLiterals(literal).map(
          scalarParser
        ).toList();
        if(candidates.any((val) => val == null)) return null;
        return attr.genericInvoke2(
          MemberOfFilter.relaxed, attr.name, candidates
        );
      }
      if( // all cases of ranges fall down to here
        literal.substring(1, literal.length - 1).split(',') case [final minLiteral, final maxLiteral]
      ) if((scalarParser(minLiteral), scalarParser(maxLiteral)) case (
        final Comparable min, final Comparable max
      )) if(max.compareTo(min) >= 0) return attr.genericInvoke3(filterCtor, attr.name, min, max);
      return null;
    }
  }

  static SingleAttributeFilter? buildLessThanFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static SingleAttributeFilter? buildGreaterThanFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      GreaterThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static SingleAttributeFilter? buildLessOrEqualFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      LessThanFilter.relaxedInclusive, attr.name, value
    )
  };

  static SingleAttributeFilter? buildGreaterOrEqualFilter(
    String literal, Attribute attr
  ) => switch(attr.match(_scalarParser)(literal)){
    null => null,
    final Comparable value => attr.genericInvoke2(
      GreaterThanFilter.relaxedNonInclusive, attr.name, value
    )
  };

  static const _scalarParser = <ScalarParser>[
    int.tryParse,
    int.tryParse,
    double.tryParse,
    int.tryParse,
    _identityString,
    _parseAbsoluteTime,
    _parseRelativeTime
  ];

  static String _identityString(String s) => s;

  static int? _parseRelativeTime(String s) {
    final result = RelativeTime.parse(s.codeUnits.iterator);
    if(result.isIncomplete || result.isInvalid) return null;
    return result.us;
  }

  static int? _parseAbsoluteTime(String s) {
    final res = AbsoluteTime.parse(s.codeUnits.iterator, DateTime.now().year);
    if(res.isIncomplete || res.isInvalid) return null;
    return res.usSinceEpoch;
  }

  static List<String> _parseCommaSeparatedLiterals(
    String literal
  ) => literal.split(RegExp(r'(?<!\\),')).map(
    (e) => e.replaceAll(RegExp(r'\\(?=[\\,])'), '')
  ).toList();
}

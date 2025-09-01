// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math' show pow, sqrt;

import '../Analyzer.dart';
import 'shared.dart';

final class NumericAnalyzer extends VectorAnalyzer {
  const NumericAnalyzer();

  @override
  Map<String, dynamic> get configPanel => MultiColumn([
    [
      LabeledCheckbox("Average", "average"),
      LabeledCheckbox("Median", "median"),
      LabeledCheckbox("Maximum", "maximum"),
      LabeledCheckbox("Minimum", "minimum"),
    ],
    [
      LabeledCheckbox("Extreme Deviation", "extremeDeviation"),
      LabeledCheckbox("Standard Deviation", "standardDeviation"),
      LabeledCheckbox("Interquartile Range", "interquartileRange"),
      LabeledCheckbox("Summation", "summation")
    ]
  ]);

  @override
  bool applicable(
    Iterable<AttrType<Comparable>> attributes
  ) => attributes.length == 1 && attributes.first.allowCast<num>();

  @override
  Map<String, dynamic> analyze(
    Iterable<GenericCandidate> vector, Map<String, Object> options
  ) {
    if(options case {
      "summation":          final bool summationOpt,
      "average":            final bool averageOpt,
      "median":             final bool medianOpt,
      "maximum":            final bool maximumOpt,
      "minimum":            final bool minimumOpt,
      "extremeDeviation":   final bool extremeDeviationOpt,
      "standardDeviation":  final bool standardDeviationOpt,
      "interquartileRange": bool interquartileRangeOpt
    }) {
      final data = vector.first.data.cast<num>();
      final length = data.length;
      interquartileRangeOpt = interquartileRangeOpt && (length > 1);

      num summation = 0, average = 0, variance = 0;
      if(summationOpt || averageOpt || standardDeviationOpt) {
        summation = data.reduce((lhs, rhs) => lhs + rhs);
        if(averageOpt) average = summation / length;
        if(standardDeviationOpt) variance = data.map(
          (val) => pow(val - average, 2)
        ).reduce((lhs, rhs) => lhs + rhs) / length;
      }
      num median = 0, maximum = 0, minimum = 0, interquartileRange = 0;
      if(medianOpt || interquartileRangeOpt) {
        final sorted = data.toList()..sort();
        minimum = sorted.first;
        maximum = sorted.last;
        median = _calcMedian(sorted);
        if(interquartileRangeOpt) {
          List<num> lowerHalf, upperHalf;
          if (length % 2 == 1) {
            // If n is odd, exclude the median from both halves.
            final medianIndex = length ~/ 2;
            lowerHalf = sorted.sublist(0, medianIndex);
            upperHalf = sorted.sublist(medianIndex + 1);
          } else {
            // If n is even, split the array evenly.
            final midIndex = length ~/ 2;
            lowerHalf = sorted.sublist(0, midIndex);
            upperHalf = sorted.sublist(midIndex);
          }

          final q1 = _calcMedian(lowerHalf);
          final q3 = _calcMedian(upperHalf);

          interquartileRange = q3 - q1;
        }
      } else if(
        maximumOpt || minimumOpt || extremeDeviationOpt
      ) for(final val in data) {
        if(val > maximum) maximum = val;
        if(val < minimum) minimum = val;
      }
      return {
        "type": "single_child_scroll_view",
        "args": { "child": Padded.symmetric(30, 15, MultiColumn([ [
          LabeledAttribute("Average: ", averageOpt ? average : "-"),
          LabeledAttribute("Median: ", medianOpt ? median : "-"),
          LabeledAttribute("Maximum: ", maximumOpt ? maximum : "-"),
          LabeledAttribute("Minimum: ", minimumOpt ? minimum : "-"),
        ], [
          LabeledAttribute("Extreme Deviation: ", extremeDeviationOpt ? maximum - minimum : "-"),
          LabeledAttribute("Standard Deviation: ", standardDeviationOpt ? sqrt(variance) : "-"),
          LabeledAttribute("Interquartile Range: ", interquartileRangeOpt ? interquartileRange : "-"),
          LabeledAttribute("Summation: ", summationOpt ? summation : "-"),
        ] ], 36, 12)) }
      };
    } else return {}; // unreachable
  }

  @override
  String get name => "Numeric";

  @override
  Map<String, Object> get options => const {
    "summation": true,
    "average": true,
    "median": true,
    "maximum": true,
    "minimum": true,
    "extremeDeviation": true,
    "standardDeviation": true,
    "interquartileRange": true
  };

  num _calcMedian(List<num> sorted) {
    if(sorted.length % 2 == 1) {
      return sorted[sorted.length ~/ 2];
    } else {
      final mid1 = sorted[sorted.length ~/ 2 - 1];
      final mid2 = sorted[sorted.length ~/ 2];
      return (mid1 + mid2) / 2;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../schema/AttrType.dart';

export '../schema/AttrType.dart' show AttrType;

final class AnalysisCandidate<T extends Iterable<Comparable?>> {
  AnalysisCandidate(this.name, this.type, this.data);

  String name;
  AttrType type;
  T data;
}

typedef GenericCandidate = AnalysisCandidate<List<Comparable?>>;

abstract class Analyzer {
  const Analyzer();

  String get name;

  bool get isVectorAnalyzer => this is VectorAnalyzer;

  /// variables that can be set by [configPanel] with there initial values
  Map<String, Object> get options;

  /// Layout of a widgets panel which sets values in options passed to
  /// [ScalarAnalyzer] or [VectorAnalyzer]
  Map<String, dynamic> get configPanel;

  /// Whether this analysis is applicable on candidates with these [attributes]
  bool applicable(Iterable<AttrType> attributes);
}

abstract class ScalarAnalyzer extends Analyzer {
  const ScalarAnalyzer();

  Map<String, dynamic> analyze(
    Iterable<(String, AttrType, Comparable?)> scalar, Map<String, Object> options
  );
}

abstract class VectorAnalyzer extends Analyzer {
  const VectorAnalyzer();

  Map<String, dynamic> analyze(
    Iterable<GenericCandidate> vector, Map<String, Object> options
  );
}

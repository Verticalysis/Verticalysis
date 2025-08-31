// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../domain/phlex/Parser.dart';
import '../../domain/phlex/Passes.dart';
import '../../domain/phlex/Primitives.dart';
import '../../domain/phlex/Types.dart';
import '../../domain/schema/AttrType.dart';
import '../../models/FiltersModel.dart';
import '../../utils/EnhancedPatterns.dart';

export '../../domain/phlex/Passes.dart' show ColumnAccessor;

typedef AttrAccessor = AttrType? Function(String name);

final class NonBooleanRuleException implements Exception {
  const NonBooleanRuleException();
}

extension on AttrAccessor {
  TypeAccessor get typeAccessor => (identifier) => switch(this(identifier)) {
    final AttrType type => _mapping[type.index],
    null => null
  };

  static const _mapping = [
    ResultType(),
    IntegerResult(),
    FloatResult(),
    IntegerResult(),
    StringResult(),
    IntegerResult(),
    IntegerResult(),
  ];
}

final class PhlexFilter extends Filter {
  PhlexFilter._(this._rule, this._label);

  factory PhlexFilter(String expression, AttrAccessor xa, ColumnAccessor ca) {
    final ta = xa.typeAccessor;
    final ast = PHLEXparser(expression).parse();
    final tfa = TFApass(ta, primitives)..visit(ast);

    if(GenerationPass(
      ta, ca, tfa.symbols
    ).visit(ast) case final Artifact<bool> rule) {
      return PhlexFilter._(rule, ASTprinter().visit(ast).toString());
    } else throw const NonBooleanRuleException();
  }

  final Artifact<bool> _rule;
  final String _label;

  @override
  List<int> filter(
    Iterable<int> index, List<V?> getTypedView<V extends Comparable>(String name)
  ) => [ for(final i in index) if(_rule(i)) i ];

  @override
  String get label => _label;

  static createNoThrow(
    String expression,
    AttrAccessor xa,
    ColumnAccessor ca,
    void onSuccess(PhlexFilter filter),
    void onException(String error, StackTrace trace)
  ) {
    try {
      onSuccess(PhlexFilter(expression, xa, ca));
    } on FormatException catch(e, trace) {
      onException("Syntax error: ${e.message}", trace);
    } on UnexpectedTypeException catch(e, trace) {
      onException("Unexpected ${e.actual.name} in a logical expression", trace);
    } on InvalidOperandException catch(e, trace) {
      onException("No overload of operator ${e.op.name} found"
      "for operands ${e.lhsType.name} and ${e.rhsType.name}", trace);
    } on OverloadMatchException catch(e, trace) {
      if(e.reasons.length == 1) {
        onException("Can't call fucntion with provided arguments:${e.reasons.first}", trace);
      } else onException("No overload matches with the argument(s)" + e.reasons.indexed.map(
        match2((i, reason) => "\nOverload $i: \n$reason")
      ).join("\n"), trace);
    } on UndefinedFunctionException catch(e, trace) {
      onException("Function ${e.function} is undefined", trace);
    } on UndefinedIdentifierException catch(e, trace) {
      onException("The referenced identifier ${e.identifier} is undefined", trace);
    } on NonBooleanRuleException catch(e, trace) {
      onException("The expression does not evaluate to a Boolean", trace);
    }
  }
}

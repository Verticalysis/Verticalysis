// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'AST.dart';
import 'Types.dart';

final class UnexpectedTypeException implements Exception {
  UnexpectedTypeException(this.expected, this.actual);

  final ResultType expected;
  final ResultType actual;
}

final class InvalidOperandException implements Exception {
  InvalidOperandException(this.op, this.lhsType, this.rhsType);

  final ResultType lhsType;
  final ResultType rhsType;
  final BinaryOperator op;
}

final class OverloadMatchException implements Exception {
  OverloadMatchException(
    Iterable<ResultType> arguments,
    Iterable<FunctionSignature> candidates
  ): reasons = candidates.map(
    (candidate) => candidate.explainMismatch(arguments)
  ).toList();

  final List<String> reasons;
}

final class UndefinedFunctionException implements Exception {
  UndefinedFunctionException(this.function);

  final String function;
}

final class UndefinedIdentifierException implements Exception {
  UndefinedIdentifierException(this.identifier);

  final String identifier;
}

typedef Artifact<T> = T Function(int index);

typedef ResolvedSymbols<T> = Map<T, FunctionSignature>;

typedef SignatureTable = Map<String, Iterable<FunctionSignature>>;

abstract class FunctionSignature {
  String get name;
  ResultType get resultType;

  Artifact Function(List<Artifact> arguments) get bind;

  const FunctionSignature();

  /// whether this function can be invoked with these [arguments]
  bool match(Iterable<ResultType> arguments);

  /// if not, explain why
  String explainMismatch(Iterable<ResultType> arguments);
}

typedef TypeAccessor = ResultType? Function(String identifier);
typedef ColumnAccessor = List Function(String identifier);

/// Type Flow Analysis and overload resolution
final class TFApass extends ASTvisitor<ResultType> {
  final TypeAccessor _typeOf;
  final SignatureTable _signatureTable;
  final ResolvedSymbols<PHLEXexpr> _resolvedSymbols = {};

  ResolvedSymbols<PHLEXexpr> get symbols => _resolvedSymbols;

  TFApass(this._typeOf, this._signatureTable);

  @override
  ResultType visitBinaryExpr(BinaryExpr expr) {
    final (lhsType, rhsType) = (visit(expr.lhs), visit(expr.rhs));
    try {
      final sig = _signatureTable.lookup(expr.op.literal, [lhsType, rhsType]);
      _resolvedSymbols[expr] = sig;
      return const BooleanResult();
    } on OverloadMatchException {
      throw InvalidOperandException(expr.op, lhsType, rhsType);
    }
  }

  @override
  ResultType visitConjunctionExpr(List<PHLEXexpr> children) {
    for(final expr in children) _expect(const BooleanResult(), expr);
    return const BooleanResult();
  }

  @override
  ResultType visitDisjunctionExpr(List<PHLEXexpr> children) {
    for(final expr in children) _expect(const BooleanResult(), expr);
    return const BooleanResult();
  }

  @override
  ResultType visitInvertedExpr(PHLEXexpr operand) {
    _expect(const BooleanResult(), operand);
    return const BooleanResult();
  }

  @override
  ResultType visitInvocationExpr(InvocationExpr expr) {
    final argTypes = expr.params.map((param) => visit(param));
    final sig = _signatureTable.lookup(expr.function, argTypes);
    _resolvedSymbols[expr] = sig;
    return sig.resultType;
  }

  @override
  ResultType visitIdentifier(String id) => switch(_typeOf(id)) {
    final ResultType type => type,
    null => throw UndefinedIdentifierException(id)
  };

  @override
  ResultType visitFloatLiteral(double value) => const FloatResult();

  @override
  ResultType visitIntegerLiteral(int value) => const IntegerResult();

  @override
  ResultType visitStringLiteral(String value) => const StringResult();

  void _expect(ResultType expected, PHLEXexpr expr) {
    final actual = visit(expr);
    if(expected.superTypeOf(expected)) return;
    throw UnexpectedTypeException(expected, actual);
  }
}

extension on SignatureTable {
  FunctionSignature lookup(String name, Iterable<ResultType> arguments) {
    if(this[name] case final Iterable<FunctionSignature> sigs) try {
      return sigs.firstWhere((sig) => sig.match(arguments));
    } on StateError {
      throw OverloadMatchException(arguments, sigs);
    } else throw UndefinedFunctionException(name);
  }
}

final class GenerationPass extends ASTvisitor<Artifact> {
  final ResolvedSymbols<PHLEXexpr> _resolvedSymbols;
  final TypeAccessor _typeOf;
  final ColumnAccessor _getColumn;

  GenerationPass(
    this._typeOf, this._getColumn, this._resolvedSymbols
  );

  @override
  Artifact<bool> visitBinaryExpr(BinaryExpr expr) {
    final BinaryExpr(:lhs, :rhs) = expr;
    final bounded = _resolvedSymbols[expr]!.bind([ visit(lhs), visit(rhs) ]);
    return (i) => bounded(i);
  }

  @override
  Artifact<bool> visitConjunctionExpr(List<PHLEXexpr> children) => (i) {
    for(final expr in children) if(!visit(expr)(i)) return false;
    return true;
  };

  @override
  Artifact<bool> visitDisjunctionExpr(List<PHLEXexpr> children) => (i) {
    for(final expr in children) if(visit(expr)(i)) return true;
    return false;
  };

  @override
  Artifact<bool> visitInvertedExpr(PHLEXexpr expr) => (i) => !visit(expr)(i);

  @override
  Artifact visitInvocationExpr(InvocationExpr expr) {
    final signature = _resolvedSymbols[expr]!;
    final bounded = signature.bind([ for(
      final param in expr.params
    ) visit(param) ]);
    return signature.resultType.genericInvoke(
      <T>() => _promote<T>((i) => bounded(i))
    );
  }

  @override
  Artifact visitIdentifier(String id) {
    final target = _getColumn(id);
    final type = _typeOf(id)!;
    return type.genericInvoke(<T>() {
      final typedTarget = target as List<T?>;
      final Artifact<T?> res = (index) => typedTarget[index];
      return res;
    });
  }

  @override
  Artifact<double> visitFloatLiteral(double value) => (_) => value;

  @override
  Artifact<int> visitIntegerLiteral(int value) => (_) => value;

  @override
  Artifact<String> visitStringLiteral(String value) => (_) => value;

  static Artifact<T> _promote<T>(Artifact artifact) => (i) => artifact(i) as T;
}

class OptionalEnclosure {
  OptionalEnclosure(this.content);

  final String content;

  String get enclosedOndemand => content;

  @override
  String toString() => content;
}

final class EnclosureCandidate extends OptionalEnclosure {
  EnclosureCandidate(super.content);

  @override
  String get enclosedOndemand => "($content)";
}

final class ASTprinter extends ASTvisitor<OptionalEnclosure> {
  final String _conjDelim = " ∧ ";
  final String _disjDelim = " ∨ ";
  final String _argsDelim = ", ";
  final String _inversion = "¬";

  static const _operators = [ "=", "≠", "<", ">", "≤", "≥" ];

  const ASTprinter();

  @override
  OptionalEnclosure visitBinaryExpr(
    BinaryExpr expr
  ) => EnclosureCandidate(
    "${visit(expr.lhs).enclosedOndemand} "
    "${_operators[expr.op.index]} "
    "${visit(expr.rhs).enclosedOndemand}"
  );

  @override
  OptionalEnclosure visitConjunctionExpr(
    List<PHLEXexpr> children
  ) => switch(children) {
    [ final single ] => visit(single),
    _ => EnclosureCandidate(
      "${children.map(visit).map(enclose).join(_conjDelim)}"
    )
  };

  @override
  OptionalEnclosure visitDisjunctionExpr(
    List<PHLEXexpr> children
  ) => switch(children) {
    [ final single ] => visit(single),
    _ => EnclosureCandidate(
      "${children.map(visit).map(enclose).join(_disjDelim)}"
    )
  };

  @override
  OptionalEnclosure visitFloatLiteral(
    double value
  ) => value.toString().enclosed;

  @override
  OptionalEnclosure visitIdentifier(String id) => id.enclosed;

  @override
  OptionalEnclosure visitIntegerLiteral(
    int value
  ) => value.toString().enclosed;

  @override
  OptionalEnclosure visitInvertedExpr(
    PHLEXexpr operand
  ) => "$_inversion${visit(operand).enclosedOndemand}".enclosed;

  @override
  OptionalEnclosure visitInvocationExpr(
    InvocationExpr expr
  ) => "${expr.function}(${expr.params.map(visit).join(_argsDelim)})".enclosed;

  @override
  OptionalEnclosure visitStringLiteral(String value) => value.enclosed;

  static String enclose(OptionalEnclosure s) => s.enclosedOndemand;
}

extension on String {
  OptionalEnclosure get enclosed => OptionalEnclosure(this);
}

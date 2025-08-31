// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';
import 'Passes.dart';
import 'Types.dart';

final class PlainFunctionSignature extends FunctionSignature {
  const PlainFunctionSignature(this.name, this.params, this.resultType, this.bind);

  final List<ResultType> params;

  @override
  final ResultType resultType;

  @override
  final String name;

  @override
  final Artifact Function(List<Artifact> arguments) bind;

  int get arity => params.length;

  @override
  bool match(Iterable<ResultType> arguments) {
    if(arguments.length != params.length) return false;
    for(final (i, arg) in arguments.indexed) if(
      !params[i].superTypeOf(arg)
    ) return false;
    return true;
  }

  @override
  String explainMismatch(
    Iterable<ResultType> arguments
  ) => arguments.length == arity ? [
    for(final (i, type) in arguments.indexed) if(
      params[i] != type
    ) "Expected a ${params[i].name} for argument $i, "
    "actual: ${type.name};"
  ].join("\n") : "Wrong number of arguments: expected $arity, "
  "got ${arguments.length}";
}

final class FlattenedSignatureTable
  with MapBase<String, Iterable<FunctionSignature>> implements SignatureTable {
  const FlattenedSignatureTable(this._signatures);

  final List<FunctionSignature> _signatures;

  @override
  Iterable<FunctionSignature>? operator [](Object? key) => switch(key) {
    final String name => _signatures.any(
      (sig) => sig.name == name
    ) ? _signatures.where((sig) => sig.name == name) : null,
    _ => throw TypeError()
  };

  @override
  void operator []=(key, value) => throw UnsupportedError(
    "FST should not be modified dynamically."
  );

  @override
  void clear() => throw UnsupportedError(
    "FST should not be modified dynamically."
  );

  @override
  Iterable<String> get keys => _signatures.map((sig) => sig.name).toSet();

  @override
  Iterable<FunctionSignature>? remove(Object? key)  => throw UnsupportedError(
    "FST should not be modified dynamically."
  );
}

Artifact<int> _primLen(List<Artifact> arguments) {
  final stringExpr = arguments.first as Artifact<String>;

  return (i) => stringExpr(i).length;
}

// Equality operator (=) - works for all types
Artifact<bool> _primEq(List<Artifact> arguments) {
  final lhs = arguments[0];
  final rhs = arguments[1];

  return (i) {
    final lval = lhs(i);
    final rval = rhs(i);

    // Different types are never equal
    if (lval.runtimeType != rval.runtimeType) {
      return false;
    }

    return lval == rval;
  };
}

Artifact<bool> _primNe(List<Artifact> arguments) {
  final eq = _primEq(arguments);
  return (i) => !eq(i);
}

Artifact<bool> _primLt(List<Artifact> arguments) {
  final lhs = arguments[0] as Artifact<num?>;
  final rhs = arguments[1] as Artifact<num?>;

  return (i) => switch((lhs(i), rhs(i))) {
    (final num lhsv, final num rhsv) => lhsv < rhsv,
    _ => false
  };
}

Artifact<bool> _primGt(List<Artifact> arguments) {
  final lhs = arguments[0] as Artifact<num?>;
  final rhs = arguments[1] as Artifact<num?>;

  return (i) => switch((lhs(i), rhs(i))) {
    (final num lhsv, final num rhsv) => lhsv > rhsv,
    _ => false
  };
}

Artifact<bool> _primLe(List<Artifact> arguments) {
  final lhs = arguments[0] as Artifact<num?>;
  final rhs = arguments[1] as Artifact<num?>;

  return (i) => switch((lhs(i), rhs(i))) {
    (final num lhsv, final num rhsv) => lhsv <= rhsv,
    _ => false
  };
}

Artifact<bool> _primGe(List<Artifact> arguments) {
  final lhs = arguments[0] as Artifact<num?>;
  final rhs = arguments[1] as Artifact<num?>;

  return (i) => switch((lhs(i), rhs(i))) {
    (final num lhsv, final num rhsv) => lhsv >= rhsv,
    _ => false
  };
}

const primitives = FlattenedSignatureTable([
  PlainFunctionSignature("len", [ StringResult() ], IntegerResult(), _primLen),

  PlainFunctionSignature("=", [
    ResultType(), ResultType()
  ], BooleanResult(), _primEq),

  PlainFunctionSignature("!=", [
    ResultType(), ResultType()
  ], BooleanResult(), _primNe),

  PlainFunctionSignature("<", [
    NumResult(), NumResult()
  ], BooleanResult(), _primLt),

  PlainFunctionSignature(">", [
    NumResult(), NumResult()
  ], BooleanResult(), _primGt),

  PlainFunctionSignature("<=", [
    NumResult(), NumResult()
  ], BooleanResult(), _primLe),

  PlainFunctionSignature(">=", [
    NumResult(), NumResult()
  ], BooleanResult(), _primGe),
]);

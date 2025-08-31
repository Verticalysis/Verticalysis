// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

class ResultType<T> {
  const ResultType();

  bool superTypeOf(ResultType type) => type is ResultType<T>;

  R genericInvoke<R>(R function<G>()) => function<T>();

  String get name => "Any";
}

class NumResult<T extends num> extends ResultType<T> {
  const NumResult();

  @override
  String get name => "Number";
}

final class IntegerResult extends NumResult<int> {
  const IntegerResult();

  @override
  String get name => "Integer";
}

final class FloatResult extends NumResult<double> {
  const FloatResult();

  @override
  String get name => "Float";
}

final class BooleanResult extends ResultType<bool> {
  const BooleanResult();

  @override
  String get name => "Bool";
}

final class StringResult extends ResultType<String> {
  const StringResult();

  @override
  String get name => "String";
}

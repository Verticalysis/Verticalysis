// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

R Function((A1, A2)) match2<R, A1, A2>(R func(A1 a1, A2 a2)) => (record) {
  final (a1, a2) = record;
  return func(a1, a2);
};

R Function((A1, A2, A3)) match3<R, A1, A2, A3>(
  R func(A1 a1, A2 a2, A3 a3)
) => (record) {
  final (a1, a2, a3) = record;
  return func(a1, a2, a3);
};

R Function((A1, A2, A3, A4)) match4<R, A1, A2, A3, A4>(
  R func(A1 a1, A2 a2, A3 a3, A4 a4)
) => (record) {
  final (a1, a2, a3, a4) = record;
  return func(a1, a2, a3, a4);
};

R Function((A1, A2, A3, A4, A5)) match5<R, A1, A2, A3, A4, A5>(
  R func(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5)
) => (record) {
  final (a1, a2, a3, a4, a5) = record;
  return func(a1, a2, a3, a4, a5);
};

R Function((A1, A2, A3, A4, A5, A6)) match6<R, A1, A2, A3, A4, A5, A6>(
  R func(A1 a1, A2 a2, A3 a3, A4 a4, A5 a5, A6 a6)
) => (record) {
  final (a1, a2, a3, a4, a5, a6) = record;
  return func(a1, a2, a3, a4, a5, a6);
};

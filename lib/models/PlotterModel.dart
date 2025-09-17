// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';
import 'dart:ui';

import 'package:flutter/foundation.dart';

final class PlotterModel extends ChangeNotifier {
  int? _points = null;
  final traces = <String>[];
  final colors = <String, Color> {};
  final colorPalette = [
    Color(0xFF00DCD6),
    Color(0xFF009A9A),
    Color(0xFF0037DC),
    Color(0xFF009A00),
  ];

  int? get points => _points;

  set points(int? pts) {
    _points = pts;
    notifyListeners();
  }

  Color colorOf(String column) => colors[column]!;

  void forceUpdate() {
    if(traces.isNotEmpty) notifyListeners();
  }

  void addTrace(String column) {
    if(traces.contains(column)) return;
    colors[column] = colorPalette[traces.length % colorPalette.length];
    traces.add(column);
    notifyListeners();
  }

  void removeTrace(String column) {
    traces.remove(column);
    colors.remove(column);
    notifyListeners();
  }

  void clearTrace() {
    traces.clear();
    colors.clear();
    notifyListeners();
  }

  void setColor(String column, Color color) {
    colors[column] = color;
    notifyListeners();
  }
}

final class Iota with ListMixin<int> {
  Iota(this.length);

  @override
  int length;

  @override
  int operator [](int index) => index;

  @override
  void operator []=(
    int index, int value
  ) => throw UnsupportedError('Cannot modify immutable view');

}

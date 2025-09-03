// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

enum Scaling { linear, chrono }

/// The scroll extents (in pixels) of the Minimap and Verticatrix are most
/// likely not the same. [ScrollModel] bridges the gap between these two by
/// storing normalized [window] and [offset] at the full scale of one. At the
/// Verticatrix side, the scaling factor depends on the mode of the Minimap.
/// In linear mode, the factor equals to the number of the current visible
/// entries, which maps the index of the last entry to 1. In chronological
/// mode, the factor equals to the time span from the earliest entry to the
/// latest entry.
final class ScrollModel extends ChangeNotifier {
  ScrollModel();

  Scaling scaling = Scaling.linear;

  double _upper = 0;
  double _lower = 0;

  double get window => _lower - _upper;
  double get offset => _upper;

  void setLowerEdge(double normalizedOffset, List<int?> refColumn) {
    _lower = _normalize(_lower, normalizedOffset, refColumn);
    notifyListeners();
  }

  /// Meant to be called when the height of the
  /// When scrolling with [scaling] = [Scaling.chrono], the window size is
  /// likely not a constant, hence both edges need to be recalculated.
  void setBothEdges(double upper, double lower, List<int?> refColumn) {
    if(refColumn.isNotEmpty) {
      _upper = _normalize(_upper, upper, refColumn);
      _lower = _normalize(_lower, lower, refColumn);
    } else {
      _upper = 0;
      _lower = 1;
    }
    notifyListeners();
  }

  double updateByDelta(
    double normalizedDelta, double normalizedHeight, List<int?> refColumn
  ) {
    if(scaling == Scaling.chrono) {
      if((refColumn.first, refColumn.last) case (int earliest, int latest)) {
        final entries = normalizedHeight.floor();
        _upper = (_upper + normalizedDelta).clamp(0, 1);
        final start = earliest + (latest - earliest) * _upper;
        final startIdx = refColumn.lowerBound(start.round(), _nullableIntCmp);
        final endIdx = startIdx + entries;
        if(endIdx >= refColumn.length) {
          _lower = 1;
          if(refColumn[max(refColumn.length - entries, 0)] case int start) {
            _lower = (start - earliest) / (latest - earliest);
          } else return _upper * refColumn.length;
        } else if(refColumn[min(endIdx, refColumn.length - 1)] case int end) {
          _lower = (end - earliest) / (latest - earliest);
        } else return _upper * refColumn.length;
        notifyListeners();
        return _upper * refColumn.length;
      } else return _upper * refColumn.length;
    } else {
      final savedWindow = window;
      _upper = (_upper + normalizedDelta).clamp(0, 1 - savedWindow);
      _lower = (_lower + normalizedDelta).clamp(savedWindow, 1);
      notifyListeners();
      return _upper * refColumn.length;
    }
  }

  // It's at best non-trivial if not entirely impossible to perform binary-
  // search on a sorted List scattered with nulls. For simplicity, we just
  // assume the reference column contains no nulls at all. Users are warned
  // that nulls in the reference column incur undefined behavior in the docs.
  int _nullableIntCmp(int? lhs, int? rhs) => switch((lhs, rhs)) {
    (final int lhs, final int rhs) => lhs.compareTo(rhs),
    _ => 1 // or whatever
  };

  double _normalize(double old, double offset, List<int?> refColumn) {
    if(scaling == Scaling.chrono) {
      if((refColumn.first, refColumn.last) case (int earliest, int latest)) {
        final start = refColumn[offset.round()];
        return start != null ? start / (latest - earliest).abs() : old;
      } else return old;
    } else return offset / refColumn.length;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

final class SelectionsModel extends ChangeNotifier {
  final _selectedIndices = SplayTreeSet<int>();

  int get count => _selectedIndices.length;

  void add(int index) {
    _selectedIndices.add(index);
    notifyListeners();
  }

  void remove(int index) {
    _selectedIndices.remove(index);
    notifyListeners();
  }

  void clear() {
    _selectedIndices.clear();
    notifyListeners();
  }

  bool isSelected(int index) => _selectedIndices.contains(index);

  Iterable<int> get selections => _selectedIndices;
}

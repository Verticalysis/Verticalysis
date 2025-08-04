// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/foundation.dart';

final class SortedModel extends ChangeNotifier {
  SortedModel(this.sortedColumn, this.descending);

  static SortedModel by((String, bool)? sortedStatus) => switch(sortedStatus) {
    (final String column, final bool desc) => SortedModel(column, desc),
    null => SortedModel(null, false)
  };

  void setStatus(String column, bool desc) {
    sortedColumn = column;
    descending = desc;
    notifyListeners();
  }

  String? sortedColumn;
  bool descending;
}

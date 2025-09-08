// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import '../../domain/schema/AttrType.dart';
import '../../models/PipelineModel.dart';
import '../../models/ProjectionsModel.dart';
import '../Verticatrix.dart';

class SearchController {
  int columnIndex = 0, rowIndex = 0;

  final VerticatrixController _vcxController;
  final PipelineModel _pipelineModel;

  int get row => rowIndex;
  String get column => _vcxController.visibleColumns[columnIndex].$1;

  SearchController(this._vcxController, this._pipelineModel);

  void reset() {
    columnIndex = 0;
    rowIndex = -1;
  }

  void _toNextColumn() {
    ++columnIndex;
    rowIndex = -1;
  }

  /// returns (found, freshStart)
  ///
  /// if found is false but freshStart is false, call [findNext] again to wrap
  /// around. Otherwise, if freshStart is true, don't call [findNext] again as
  /// we have already iterated all cells
  (bool, bool) findNext(String keyword, bool caseSensitive) {
    final lowerCaseKeyword = keyword.toLowerCase();
    bool freshStart = columnIndex == 0 && rowIndex == -1;

    while(true) {
      final columns = _vcxController.visibleColumns;
      if(columns.isEmpty || _vcxController.entries == 0) return (false, false);

      // recheck in case that columns were altered
      if(rowIndex >= _vcxController.entries) _toNextColumn();

      if(columnIndex >= columns.length) columnIndex = 0;
      final (columnName, columnEntries) = columns[columnIndex];
      final type = _pipelineModel.getAttrTypeByName(columnName);
      if(type == AttrType.string) {
        rowIndex = columnEntries.indexWhere(_matcher(
          keyword, lowerCaseKeyword, caseSensitive
        ), rowIndex + 1);
      } else rowIndex = (
        columnEntries as StringfiedView
      ).typedView.indexWhere(type.tryParse(keyword).matches, rowIndex + 1);
      if(rowIndex != -1) {
        return (true, freshStart);
      } else { // search reached the end of a column
        _toNextColumn();

        if(columnIndex >= columns.length) { // search reached the end
          reset();
          return (false, freshStart);
        }
      }
    }
  }

  void highlightMatch() => _vcxController.highlight(rowIndex, column);

  static bool Function(String? _) _matcher(
    String keyword, String lowerCaseKeyword, bool caseSensitive
  ) => caseSensitive ? keyword.partOfMatchCase : lowerCaseKeyword.partOf;
}

extension on AttrType {
  Comparable? tryParse(String literal) {
    try {
      return this.from(literal);
    } catch(_) {
      return null;
    }
  }
}

extension on String {
  bool partOfMatchCase(String? str) => str != null ? str.contains(this) : false;
  bool partOf(String? str) => str != null ? str.toLowerCase().contains(this) : false;
}

extension on Comparable? {
  bool matches(Comparable? rhs) => rhs != null ? rhs == this : false;
}

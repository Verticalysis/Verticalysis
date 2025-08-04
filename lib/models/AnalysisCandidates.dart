// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/foundation.dart';

import '../domain/analysis/Analyzer.dart';
import '../domain/schema/AttrType.dart';
import 'ProjectionsModel.dart';


final class AnalysisCandidates extends ChangeNotifier {
  int start = 0;
  int end = 0;
  double numberColWidth = 0;

  bool get isEmpty => start == end;
  int get length => end - start;

  List<AnalysisCandidate<StringfiedView>> _columns = const [];

  Iterable<(String, Iterable<String?>)> get stringfied sync* {
    for(final column in _columns) {
      yield (column.name, column.data.take(end).skip(start));
    }
  }

  Iterable<GenericCandidate> get candidates => _columns.map(
    (candidate) => AnalysisCandidate(
      candidate.name,
      candidate.type,
      candidate.data.typedView.take(end).skip(start)
    )
  );

  AnalysisCandidate getCandidate(String column) => _columns.firstWhere(
    (candidate) => candidate.name == column
  );

  void update(
    List<AnalysisCandidate<StringfiedView>> columns,
    int startRow,
    int endRow,
  ) {
    start = startRow;
    end = endRow;
    _columns = columns;
    numberColWidth = end.toString().length * 10;
    notifyListeners();
  }
}

/*import 'package:flutter/foundation.dart';
import 'package:sticky_and_expandable_list/sticky_and_expandable_list.dart';

import '../domain/utils/ListView.dart';

final class AttrToAnalyze extends ChangeNotifier/*<T extends Comparable>*/
  implements ExpandableListSection<String?> {
  AttrToAnalyze(this.attrName, this.column, this.start, this.end);

  final List<String?>/*<T>*/ column;
  final String attrName;

  int start;
  int end;

  bool expanded = true;

  String itemAt(int index) => column[index + start] ?? "";

  @override
  List<String?> getItems() => ListView.fromRange(column, start, end);

  @override
  bool isSectionExpanded() => expanded;

  @override
  void setSectionExpanded(bool expanded) {
    expanded = expanded;
    notifyListeners();
  }

  void toggleExpand() => setSectionExpanded(!expanded);
}

extension AnalyzeModel on ValueNotifier<List<AttrToAnalyze>> {
  void toggleExpand(int index) {
    this.value[index].toggleExpand();
    this.value = List.of(this.value);
  }

  void update(
    Iterator<List<String?>> columns,
    Iterable<String> columnNames,
    int start,
    int end
  )=> this.value = columnNames.map(
    (name) => AttrToAnalyze(name, (columns..moveNext()).current, start, end)
  ).toList();
}
*/

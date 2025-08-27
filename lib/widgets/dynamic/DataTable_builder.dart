// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:json_dynamic_widget/json_dynamic_widget.dart';

import 'utils.dart';

part 'DataTable_builder.g.dart';

@jsonWidget
abstract class _DataTableBuilder extends JsonWidgetBuilder {
  const _DataTableBuilder({
    required super.args,
  });

  @override
  _DataTable buildCustom({
    ChildWidgetBuilder? childBuilder,
    required BuildContext context,
    required JsonWidgetData data,
    Key? key,
  });
}

class _DataTable extends StatelessWidget {
  const _DataTable({
    List rows = const [],
    List columns = const [],
    double? dataRowMinHeight,
    double? dataRowMaxHeight,
    Map? dataTextStyle,
    double? headingRowHeight,
    Map? headingTextStyle,
    double? horizontalMargin,
    double? columnSpacing,
    bool showCheckboxColumn = true,
    bool showBottomBorder = false,
    double? dividerThickness,
    double? checkboxHorizontalMargin,
  }): _rows = rows,
    _columns = columns,
    _dataRowMinHeight = dataRowMinHeight,
    _dataRowMaxHeight = dataRowMaxHeight,
    _dataTextStyle = dataTextStyle,
    _headingRowHeight = headingRowHeight,
    _headingTextStyle = headingTextStyle,
    _horizontalMargin = horizontalMargin,
    _columnSpacing = columnSpacing,
    _showCheckboxColumn = showCheckboxColumn,
    _showBottomBorder = showBottomBorder,
    _dividerThickness = dividerThickness,
    _checkboxHorizontalMargin = checkboxHorizontalMargin;

  final List _rows;
  final List _columns;
  final double? _dataRowMinHeight;
  final double? _dataRowMaxHeight;
  final Map? _dataTextStyle;
  final double? _headingRowHeight;
  final Map? _headingTextStyle;
  final double? _horizontalMargin;
  final double? _columnSpacing;
  final bool _showCheckboxColumn;
  final bool _showBottomBorder;
  final double? _dividerThickness;
  final double? _checkboxHorizontalMargin;

  @override
  Widget build(BuildContext context) {
    final columns = <DataColumn>[];
    if(_columns case [String _, ...]) columns.addAll(
      _columns.map((column) => DataColumn(label: Text(column as String)))
    ); else if(_columns case [Map _, ...]) _columns.map((column) => DataColumn(
      label: Text(column["label"]),
      columnWidth: column["columnWidth"],
      tooltip: column["tooltip"],
      numeric: column["numeric"] ?? false,
    )); else throw ArgumentError("column must be a non-empty list of strings or maps");
    return DataTable(
      columns: columns,
      rows: [ for(final row in _rows) DataRow(
          cells: <DataCell> [ for(final cell in row) DataCell(Text(cell)) ],
      ) ] ,
      dataRowMinHeight: _dataRowMinHeight,
      dataRowMaxHeight: _dataRowMaxHeight,
      dataTextStyle: _dataTextStyle?.asTextStyle,
      headingRowHeight: _headingRowHeight,
      headingTextStyle: _headingTextStyle?.asTextStyle,
      horizontalMargin: _horizontalMargin,
      columnSpacing: _columnSpacing,
      showCheckboxColumn: _showCheckboxColumn,
      showBottomBorder: _showBottomBorder,
      dividerThickness: _dividerThickness,
      checkboxHorizontalMargin: _checkboxHorizontalMargin,
    );
  }
}

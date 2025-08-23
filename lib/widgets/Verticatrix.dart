// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:math' show min, max;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:verticalysis_linked_scroll_controller/linked_scroll_controller.dart';

import '../utils/EnhancedPatterns.dart';

typedef NamedColumn = (String, List<String?>);
typedef RegionVisitor<T> = T Function(
  int startRow, int endRow, Iterable<(String, List<String?>)> data
);

extension on NamedColumn {
  bool named(String name) => match2((col, _) => col == name)(this);
}

final class VerticatrixController {
  void Function(/*double position*/) onScroll = () {};

  final TableState tableState;
  final regionState = RegionState();
  final _entries = ValueNotifier(0);

  final columnWidths = <String, ValueNotifier<double>> {};

  final LinkedScrollControllerGroup verticalControllers;
  final Map<String, ScrollController> columnControllers;
  final ScrollController rowHeaderController;
  final ScrollController horizontalController;

  // final ValueNotifier<DragState?> dragStateNotifier;
  double prevPointerPosX = 0;
  double initialColWidth = 0;
  bool isResizing = false;
  bool seekScroll = false;

  double cellHeight = 0;

  RegionVisitor<void> onRegionSelect = (_, _, _) {};

  VerticatrixController([
    Iterable<NamedColumn> initialColumns = const [],
    Map<String, double> initialWidths = const {}
  ]): this._(initialColumns, initialWidths, LinkedScrollControllerGroup());

  VerticatrixController._(
    Iterable<NamedColumn> initialColumns,
    Map<String, double> initialWidths,
    LinkedScrollControllerGroup scrollControllerGroup
  ): tableState = TableState(initialColumns),
     verticalControllers = scrollControllerGroup,
     rowHeaderController = scrollControllerGroup.addAndGet(),
     horizontalController = ScrollController(),
     columnControllers = Map.fromEntries(initialColumns.map(match2(
       (col, _) => MapEntry(col, scrollControllerGroup.addAndGet())
     ))) {
    verticalControllers.addOffsetChangedListener(() {
      regionState.scrollUpdate();
      if(seekScroll) { // Programmatic seek, ignore
        seekScroll = false;
      } else onScroll(/*verticalControllers.offset*/);
    });
  }

  set entries(int count) => _entries.value = count;
  int get entries => _entries.value;

  double get scrollPosition => rowHeaderController.offset;
  double get viewPortHeight => rowHeaderController.position.viewportDimension;
  double get normalizedOffset => verticalControllers.offset / cellHeight;
  double get normalizedHeight => viewPortHeight / cellHeight;
  double normalizedLowerEdge() => min((
    verticalControllers.offset + viewPortHeight
  ) / cellHeight, entries.toDouble());

  List<NamedColumn> get visibleColumns => tableState.activeColumns;

  void regScrollController(
    String column
  ) => columnControllers.putIfAbsent(column, verticalControllers.addAndGet);

  void highlight(int index, String column) {
    scroll2index(index.toDouble());
    regionState.selectSingle(index, visibleColumns.indexWhere(
      (col) => col.named(column)
    ));
  }

  void scroll2index(double index) {
    verticalControllers.jumpTo(index * cellHeight);
    seekScroll = true;
  }

  void scroll2column(String column) {
    horizontalController.jumpTo(colsWidth((TableState tableState, String column) sync* {
      for(final (name, _) in tableState.activeColumns) if(name == column) {
        break;
      } else yield name;
    } (tableState, column)));
    seekScroll = true;
  }

  bool hasActiveColumn(String name) => tableState.activeColumns.contains(name);

  void addColumn(String name, List<String?> columns) {
    visibleColumns.add((name, columns));
    regScrollController(name);
    tableState.update();
  }

  void syncWith(VerticatrixController src) {
    tableState.activeColumns..clear()..addAll(src.tableState.activeColumns);
    tableState.hiddenColumns..clear()..addAll(src.tableState.hiddenColumns);
    for(final (id, _) in src.tableState.activeColumns) regScrollController(id);
    for(final (id, _) in src.tableState.hiddenColumns) regScrollController(id);
    tableState.update();
  }

  void syncColumns(List<String?> columnCtor(String name), int length) {
    for(final (index, (name, _)) in tableState.activeColumns.indexed) {
      tableState.activeColumns[index] = (name, columnCtor(name));
    }
    for(final (index, (name, _)) in tableState.hiddenColumns.indexed) {
      tableState.hiddenColumns[index] = (name, columnCtor(name));
    }
    _entries.value = length;
    tableState.update();
  }

  T acceptRegionVisitor<T>(RegionVisitor<T> visitor) => visitor(
    regionState.upperEdge,
    regionState.lowerEdge + 1,
    tableState.activeColumns.skip(regionState.leftEdge).take(
      regionState.rightEdge - regionState.leftEdge + 1
    )
  );

  double colsWidth(Iterable<String> cols) => cols.map(
    (col) => columnWidths[col]!.value
  ).reduce((lhs, rhs) => lhs + rhs);

  void dispose() {}
}

final class RegionState extends ChangeNotifier {
  int regionStartCol = -1;
  int regionEndCol = -1;
  int regionStartRow = -1;
  int regionEndRow = -1;

  int get upperEdge => min(regionStartRow, regionEndRow);
  int get lowerEdge => max(regionStartRow, regionEndRow);
  int get rightEdge => max(regionStartCol, regionEndCol);
  int get leftEdge => min(regionStartCol, regionEndCol);

  bool get notEmpty => regionStartCol != -1 && regionEndCol != -1;

  bool updating = false;

  bool regionSelected(int rowIndex, int colIndex) => notEmpty
    && rowIndex.isWithin(regionStartRow, regionEndRow)
    && colIndex.isWithin(regionStartCol, regionEndCol);

  void regionReset() {
    final active = notEmpty;
    regionStartCol = regionEndCol = regionStartRow = regionEndRow = -1;
    if(active) notifyListeners();
  }

  void regionUpdate(int endRow, int endCol) {
    regionEndRow = endRow;
    regionEndCol = endCol;
    notifyListeners();
  }

  void selectSingle(int row, int column) {
    regionStartCol = regionEndCol = column;
    regionStartRow = regionEndRow = row;
    notifyListeners();
  }

  void selectColumn(int column, int count) {
    regionStartCol = regionEndCol = column;
    regionStartRow = 0;
    regionEndRow = count - 1;
    notifyListeners();
  }

  void scrollUpdate() => notifyListeners();
}

final class TableState extends ChangeNotifier {
  final List<NamedColumn> activeColumns;
  final hiddenColumns = <NamedColumn>[];

  TableState(Iterable<NamedColumn> columns): activeColumns = List.of(columns);

  bool get hasHiddenCols => hiddenColumns.isNotEmpty;

  void hideColumn(int colIndex) {
    hiddenColumns.add(activeColumns.removeAt(colIndex));
    notifyListeners();
  }

  void restoreToIndex(String column, int colIndex) {
    hiddenColumns.removeWhere((col) {
      if(!col.named(column)) return false;
      activeColumns.insert(colIndex, col);
      return true;
    });

    notifyListeners();
  }

  /*void restoreAllHidden() {
    for(final (column, index) in hiddenColumns) {
      if(index < activeColumns.length) {
        activeColumns.insert(index, column);
      } else activeColumns.add(column);
    }
    hiddenColumns.clear();
  }*/

  void update() => notifyListeners();
}

extension on int {
  bool isWithin(int l, int r) => this >= min(l, r) && this <= max(l, r);
}

typedef TrayBuilder = InlineSpan Function(String columnName, int rowIndex);
typedef RowHeaderBuilder = Widget Function(BuildContext context, int rowIndex);
typedef HeaderBuilder = Widget Function(
  BuildContext context,
  String columnName,
  TextStyle style,
  double height
);

final class Verticatrix extends StatelessWidget {
  final VerticatrixController controller;
  final ChangeNotifier rowHeaderRebuildNotifier;

  final HeaderBuilder headerBuilder;
  final RowHeaderBuilder rowHeaderBuilder;
  // final TrayBuilder lineTrayBuilder;

  // final void Function(int rowIndex, dynamic content, String columnName) cellOnTap;

  final double minColumnWidth;
  final double maxColumnWidth;
  final double cellHeight;
  final double headerExtraSpace;
  final EdgeInsets cellPadding;
  final TextStyle textStyle;
  final TextStyle ctxMenuTextStyle;

  final Color ctxMenuColor;
  final Color colEdgeColor;
  final Color evenRowColor;
  final Color headerBackground;

  final BoxDecoration selectedRegionOutline;

  final Iterable<(String, String, RegionVisitor<String>)> formatters;

  Map<String, ValueNotifier<double>> get columnWidths => controller.columnWidths;
  final _isDragging = ValueNotifier(false);
  RegionState get regionState => controller.regionState;

  static const _ctxMenuItemHeight = 32.0;

  Verticatrix({
    super.key,
    required this.controller,
    required this.headerBuilder,
    required this.rowHeaderBuilder,
    required this.rowHeaderRebuildNotifier,
    // required this.lineTrayBuilder,
    // required this.cellOnTap,
    required this.headerExtraSpace,
    required this.cellHeight,
    required this.cellPadding,
    required this.textStyle,
    required this.ctxMenuTextStyle,
    required this.evenRowColor,
    required this.ctxMenuColor,
    required this.colEdgeColor,
    required this.headerBackground,
    required this.selectedRegionOutline,
    required this.formatters,
    this.minColumnWidth = 100.0,
    this.maxColumnWidth = double.infinity,
  }) {
    controller.cellHeight = cellHeight;
  }

  int visibleItems(double height) => height ~/ cellHeight;

  TableState get tableState => controller.tableState;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<int>( // Row Header Column
          valueListenable: controller._entries,
          builder: (context, entries, child) => SizedBox(
            width: _estimateWidth(entries.toString(), textStyle, 21),
            child: ScrollConfiguration(
              behavior: _removeScrollBar(context),
              child: Column(children: [
                headerBuilder(context, "", textStyle, cellHeight),
                Expanded(child: ListenableBuilder(
                  listenable: rowHeaderRebuildNotifier,
                  builder: (context, _) => ListView.builder(
                    controller: controller.rowHeaderController,
                    itemExtent: cellHeight,
                    itemCount: entries,
                    itemBuilder: (context, index) => SizedBox(
                      child: rowHeaderBuilder(context, index),
                      height: cellHeight,
                    )
                  ),
                )),
              ])
            ),
          )
        ),
        SizedBox( // Divider for header column
          width: 0.5,
          height: double.infinity,
          child: ColoredBox(color: colEdgeColor)
        ),
        Expanded(child: Scrollbar( // Scrollable Columns Area
          controller: controller.horizontalController,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: controller.horizontalController,
            child: ScrollConfiguration(
              behavior:  _removeScrollBar(context),
              child: ListenableBuilder(
                listenable: controller.tableState,
                builder: (context, _) => Listener(
                  onPointerUp: (_) {
                    regionState.updating = false;
                    if(regionState.notEmpty) controller.acceptRegionVisitor(
                      controller.onRegionSelect
                    );
                  },
                  child: Stack(children: [
                    SizedBox(
                      height: cellHeight,
                      width: constraints.maxWidth,
                      child: ColoredBox(color: headerBackground)
                    ),
                    ListenableBuilder(
                      listenable: regionState,
                      builder: (ctx, _) => regionState.notEmpty ? Positioned(
                        left: cellsWidth(0, regionState.leftEdge),
                        top: (regionState.upperEdge + 1) * cellHeight -
                          controller.verticalControllers.offset,
                        child: IgnorePointer(child: Container(
                          decoration: selectedRegionOutline,
                          height: (
                            regionState.lowerEdge - regionState.upperEdge + 1
                          ) * cellHeight,
                          width: cellsWidth(
                            regionState.leftEdge,
                            regionState.rightEdge + 1
                          ),
                        )
                      )) : const SizedBox.shrink()
                    ),
                    Row(children: [
                      for(
                        final (index, (name, entries))
                        in tableState.activeColumns.indexed
                      ) ValueListenableBuilder<double>(
                        valueListenable: columnWidths.putIfAbsent(
                          name, () => ValueNotifier(_estimateWidth(
                            name, textStyle, headerExtraSpace
                          ).clamp(minColumnWidth, maxColumnWidth))
                        ),
                        builder: (context, widths, _) => _buildColumn(
                          name,
                          entries,
                          index,
                          widths,
                          context,
                          constraints.maxHeight,
                        )
                      ),
                      /*Align(alignment: Alignment.topCenter, child: SizedBox(
                        width: max(constraints.maxWidth - (
                          tableState.activeColumns.isEmpty ?
                          0 :
                          colsWidth(tableState.activeColumns)
                        ), 0),
                        child: headerBuilder(context, "", textStyle, cellHeight)
                      ))*/
                    ]),
                  ])
                )
              )
            )
          )
        )),
      ]
    )
  );

  Widget _buildColumn(
    String columnName,
    List<String?> data,
    int colIndex,
    double columnWidth,
    BuildContext context,
    double height,
  ) => DragTarget<String>(
    onWillAcceptWithDetails: (draggedColumn) {
      regionState.regionReset();
      if (draggedColumn == columnName) return false;
      return true;
    },
    onAcceptWithDetails: (details) {
      _insertColumn(details.data, columnName);
      regionState.regionReset();
    },
    builder: (context, candidateData, rejectedData) => SizedBox(
      width: columnWidth,
      child: Stack(children: [
        Column(
          children: [
            Draggable<String>( // Header
              data: columnName,
              axis: Axis.horizontal,
              child: GestureDetector(
                onSecondaryTapUp: (details) {
                  regionState.regionReset();
                  showMenu(
                    context: context,
                    menuPadding: const EdgeInsets.all(0),
                    color: ctxMenuColor,
                    position: _popupPosition(details.globalPosition, context),
                    items: [
                      PopupMenuItem<Never>(
                        child: Text('Copy', style: ctxMenuTextStyle),
                        height: _ctxMenuItemHeight,
                        mouseCursor: MouseCursor.defer,
                        onTap: () => _copy2clipboard(columnName)
                      ),
                      PopupMenuItem<Never>(
                        child: Text('Select column', style: ctxMenuTextStyle),
                        onTap: () => regionState.selectColumn(
                          colIndex, controller._entries.value
                        ),
                        height: _ctxMenuItemHeight,
                        mouseCursor: MouseCursor.defer,
                      ),
                      PopupMenuItem<Never>(
                        child: Text('Hide', style: ctxMenuTextStyle),
                        onTap: () => tableState.hideColumn(colIndex),
                        height: _ctxMenuItemHeight,
                        mouseCursor: MouseCursor.defer,
                      ),
                      if(tableState.hasHiddenCols) PopupMenuItem<Never>(
                        child: Text('Restore hidden', style: ctxMenuTextStyle),
                        height: _ctxMenuItemHeight,
                        enabled: false,
                      ),
                      if(tableState.hasHiddenCols) for(
                        final (name, _) in tableState.hiddenColumns
                      ) PopupMenuItem<Never>(
                        child: Text(name, style: ctxMenuTextStyle),
                        onTap: () => tableState.restoreToIndex(name, colIndex),
                        height: _ctxMenuItemHeight,
                        mouseCursor: MouseCursor.defer,
                      )
                    ],
                  );
                },
                child: SizedBox(
                  width: columnWidth,
                  child: headerBuilder(
                    context,
                    columnName,
                    textStyle,
                    cellHeight
                  )
                )
              ),
              feedback: //Material(
                //elevation: 0,
                //child:
                SizedBox(
                  width: columnWidth,
                  height: height,
                  child:  ClipRect(child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Column(children: [
                      headerBuilder(context, columnName, textStyle, cellHeight),
                      Expanded(child: ValueListenableBuilder<int>(
                        valueListenable: controller._entries,
                        builder: (context, entries, _) => ListView.builder(
                          key: UniqueKey(),
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visibleItems(height),
                          itemBuilder: (context, index) => _buildCell(
                            data.elementAtOrNull(
                              index + controller.normalizedOffset.floor()
                            ) ?? "",
                            index,
                            -1,
                            columnName,
                            context,
                            height: cellHeight,
                            selectable: false,
                            background: evenRowColor
                          ),
                        )
                      )),
                    ]),
                  ))
                ),
              //),
              onDragStarted: () {
                regionState.regionReset();
                _isDragging.value = true;
              },
              onDragUpdate: (_) => Tooltip.dismissAllToolTips(),
              onDragEnd: (_) {
                _isDragging.value = false;
              },
            ),
            // Column content
            Expanded(child: ValueListenableBuilder<int>(
              valueListenable: controller._entries,
              builder: (context, entries, _) => ListView.builder(
                key: ValueKey(columnName),
                padding: EdgeInsets.all(0.0),
                controller: controller.columnControllers[columnName],
                itemExtent: cellHeight,
                itemCount: entries,
                itemBuilder: (context, rowIndex) => _buildCell(
                  data[rowIndex] ?? "",
                  rowIndex,
                  colIndex,
                  columnName,
                  context,
                  height: cellHeight,
                  selectable: true,
                  background: rowIndex & 1 == 0 ? null : evenRowColor,
                  ctxmenu: [
                    if(!controller.regionState.notEmpty) PopupMenuItem<Never>(
                      child: Text('Copy', style: ctxMenuTextStyle),
                      height: _ctxMenuItemHeight,
                      mouseCursor: MouseCursor.defer,
                      onTap: () => _copy2clipboard(data[rowIndex] ?? "")
                    ),
                    PopupMenuItem<Never>(
                      child: Text('Copy as', style: ctxMenuTextStyle),
                      height: _ctxMenuItemHeight,
                      enabled: false,
                    ),
                    for(final (name, _, formatter) in formatters) PopupMenuItem<Never>(
                      child: Text(name, style: ctxMenuTextStyle),
                      height: _ctxMenuItemHeight,
                      mouseCursor: MouseCursor.defer,
                      onTap: () => _copy2clipboard(
                        controller.acceptRegionVisitor(formatter)
                      )
                    )
                  ]
                ),
              ),
            )),
          ]),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isDragging,
              child: Container(
                width: 10, // Hit-test area (10 pixels left of separator)
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(right: BorderSide(
                    width: 0.5, color: ColorScheme.of(context).onSurface
                  )),
                )
              ),
              builder: (context, isDragging, divider) => isDragging ?
              divider! :
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                opaque: false,  // pass through scroll event
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    controller.prevPointerPosX = details.globalPosition.dx;
                    controller.initialColWidth = columnWidth;
                    controller.isResizing = true;
                    regionState.regionReset();
                  },
                  onPanUpdate: (details) {
                    final newWidth = controller.initialColWidth
                      + details.globalPosition.dx
                      - controller.prevPointerPosX;
                    if(newWidth >= minColumnWidth) columnWidths[
                      columnName
                    ]!.value = newWidth;
                  },
                  onPanEnd: (_) => controller.isResizing = false,
                  child: divider!
                ),
              ),
            )
          ),
        ]
      )
    )
  );

  Widget _buildCell(
    String content,
    int rowIndex,
    int colIndex,
    String columnName,
    BuildContext context, {
    required double height,
    required bool selectable,
    Color? background,
    List<PopupMenuEntry> ctxmenu = const []
  }) => MouseRegion(
    onEnter: selectable ? (detail) {
      if(_isDragging.value) return;
      if(regionState.updating && !controller.isResizing) {
        regionState.regionUpdate(rowIndex, colIndex);
      }
    } : null,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: selectable ? (_) {
        if(_isDragging.value) return;
        regionState.updating = true;
        regionState.regionStartRow = rowIndex;
        regionState.regionStartCol = colIndex;
      } : null,
      onTap: () {
        regionState.updating = false;
        if(_isDragging.value) return;
        // cellOnTap(rowIndex, content, columnName);
        if(!controller.isResizing) regionState.regionReset();
        if(selectable) {
          regionState.selectSingle(rowIndex, colIndex);
          controller.acceptRegionVisitor(
            controller.onRegionSelect
          );
        }
      },
      onSecondaryTapUp: (details) {
        if(!regionState.regionSelected(
          rowIndex, colIndex
        )) regionState.regionReset();
        if(ctxmenu.isNotEmpty) showMenu(
          menuPadding: EdgeInsets.all(0),
          color: ctxMenuColor,
          context: context,
          position: _popupPosition(details.globalPosition, context),
          items: ctxmenu,
        );
      },
      child: Container(
        // decoration: BoxDecoration(border: _vertRuler,),
        height: height,
        padding: cellPadding,
        alignment: Alignment.centerLeft,
        color: background,
        child: Text(
          content,
          overflow: TextOverflow.fade,
          style: textStyle,
          softWrap: false,
          maxLines: 1,
        )
      ),
    ),
  );

  // https://stackoverflow.com/a/54714628/10627291
  RelativeRect _popupPosition(
    Offset position, BuildContext context
  ) => RelativeRect.fromRect(
    position & const Size(40, 40),
    Offset.zero & Overlay.of(
      context
    ).context.findRenderObject()!.semanticBounds.size
  );


  ScrollBehavior _removeScrollBar(
    BuildContext context
  ) => ScrollConfiguration.of(context).copyWith(scrollbars: false);

  void _insertColumn(String draggedColumn, String targetColumn) {
    final order = tableState.activeColumns;
    final targetIndex = order.indexWhere((col) => col.named(targetColumn));
    final draggedIndex = order.indexWhere((col) => col.named(draggedColumn));
    order.insert(targetIndex, order.removeAt(draggedIndex));
    tableState.update();
  }

  double cellsWidth(
    int start, int end
  ) => end != 0 ? controller.colsWidth((Iterable<NamedColumn> cols) sync* {
    for(final(name, _) in cols) yield name;
  } (tableState.activeColumns.skip(start).take(end - start))) : 0;

  static void _copy2clipboard(
    String content
  ) => Clipboard.setData(ClipboardData(text: content));

  static double _estimateWidth(String content, TextStyle style, double extra) {
    final painter = TextPainter(
      text: TextSpan(text: content, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return painter.width + extra;
  }
}

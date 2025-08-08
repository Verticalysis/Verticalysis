// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';

import '../models/FiltersModel.dart';
import '../models/ProjectionsModel.dart';
import '../models/SelectionsModel.dart';
import 'helper/Events.dart';
import 'helper/FilterMode.dart';
import 'shared/Extensions.dart';
import 'shared/Select.dart';
import 'MonitorMode.dart';
import 'Style.dart';

extension WithTooltip on Widget {
  Widget withTooltip(BuildContext context, Widget tooltip) => Tooltip(
    enableTapToDismiss: false,
    verticalOffset: 18,
    padding: const EdgeInsets.all(0),
    waitDuration: const Duration(milliseconds: 300),
    exitDuration: const Duration(milliseconds: 90),
    decoration: BoxDecoration(
      color: ColorScheme.of(context).surface,
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      boxShadow: [BoxShadow(
        offset: const Offset(1.0, 1.0),
        color: ColorScheme.of(context).onSurface,
        blurRadius: 1.5
      )]
    ),
    richMessage: WidgetSpan(child: tooltip),
    child: this
  );
}

extension type Header._(Container container) implements Widget {
  Header(
    BuildContext context,
    String columnName,
    TextStyle style,
    double height,
    ProjectionsModel projectionsModel
  ): container = Container(
    height: height,
    color: ColorScheme.of(context).surface,
    padding: const EdgeInsets.symmetric(horizontal: cellPadding),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(columnName, style: TextTheme.of(context).bodyMedium),
        switch(projectionsModel.current.currentlySortedBy) {
          (final column, true) => column == columnName ? Icon(
            Icons.arrow_drop_down,
            color: ColorScheme.of(context).onSurfaceVariant,
            size: 15,
          ) : const SizedBox.shrink(),
          (final column, false) => column == columnName ? Icon(
            Icons.arrow_drop_up,
            color: ColorScheme.of(context).onSurfaceVariant,
            size: 15,
          ) : const SizedBox.shrink(),
          null => const SizedBox.shrink(),
        }
      ]
    ),
  );
}

extension type PrimaryHeaderBuilder(MonitorMode toplevel) {
  Widget build(
    BuildContext context,
    String columnName,
    TextStyle style,
    double height
  ) => columnName.isNotEmpty ? Header(
    context, columnName, style, height, toplevel.projectionsModel
  ).withTooltip(context, HeaderTray(columnName, toplevel)) : Header(
    context, columnName, style, height, toplevel.projectionsModel
  );
}

extension type CollectHeaderBuilder(ProjectionsModel projections) {
  Widget build(
    BuildContext context,
    String columnName,
    TextStyle style,
    double height
  ) => columnName.isNotEmpty ? Header(
    context, columnName, style, height, projections
  ).withTooltip(context, CollectHeaderTray(projections, columnName)) : Header(
    context, columnName, style, height, projections
  );
}

extension type SortButton(ProjectionsModel projections) {
  T isSorted<T>(String attribute, T sorted, T unsorted, bool descending) {
    final sortStatus = projections.current.currentlySortedBy;
    if(sortStatus == null) return unsorted;
    final (column, desc) = sortStatus;
    if(column != attribute) return unsorted;
    return desc == descending ? sorted : unsorted;
  }

  Widget build(
    BuildContext context,  String attribute, bool descending
  ) => IconButton(
    icon: RotatedBox(quarterTurns: descending ? 2 : 0, child: Icon(
      Icons.sort, color: ColorScheme.of(context).onSurface)
    ),
    onPressed: () => projections.sort(attribute, descending),
    style: IconButton.styleFrom(
      shape: const RoundedRectangleBorder(borderRadius: rectBorder),
      fixedSize: const Size.square(13.5),
      backgroundColor: isSorted(
        attribute,
        ColorScheme.of(context).primary,
        ColorScheme.of(context).surface,
        descending,
      )
    ),
  );
}

enum HeaderTrayMode { normal, filterEdit }

final class HeaderTray extends StatelessWidget {
  final _mode = ValueNotifier(HeaderTrayMode.normal);
  final _filterMode = ValueNotifier(FilterMode.equality);
  final MonitorMode toplevel;
  final String attribute;
  final Channel<Notifer1<Filter>> _filterAppendCh;
  final _timer = Stream<Never?>.periodic(
    const Duration(milliseconds: 90)
  ).listen(null)..pause();

  String get filterMode => _filterMode.value == FilterMode.interval ? "range" : "value";

  final _buttonStyle = IconButton.styleFrom(
    shape: const RoundedRectangleBorder(borderRadius: rectBorder),
    fixedSize: const Size.square(12),
  );

  HeaderTray(
    this.attribute, this.toplevel
  ): _filterAppendCh = toplevel.dispatcher.getChannel(Event.filterAppend);

  void exitFilterEdit() {
    _timer..onData(null)..pause();
    Tooltip.dismissAllToolTips();
    _mode.value = HeaderTrayMode.normal;
  }

  void filterEditSubmit(String predicate) {
    final attr = toplevel.pipelineModel.getAttributeByName(attribute);
    if(_filterMode.value.buildFilter(
      predicate.trim(), attr
    ) case final SingleAttributeFilter filter) {
      _filterAppendCh.notify(filter);
    } else alertError("Invalid condition", "Input is not a valid $filterMode");
    exitFilterEdit();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _mode,
    builder: (context, mode, _) => switch(mode) {
      HeaderTrayMode.normal => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton( // build a filter with this column
            icon: Icon(
              Icons.filter_alt, color: ColorScheme.of(context).onSurface
            ),
            style: _buttonStyle,
            onPressed: () {
              _mode.value = HeaderTrayMode.filterEdit;
              // The drop down menu in filter edit mode paints outside the
              // tooltip, therefore, moving the cursor into it dismisses the
              // tooltip. This  keeps the tooltip visible.
              final state = context.findAncestorStateOfType<TooltipState>()!;
              _timer..onData((_) {
                Tooltip.dismissAllToolTips();
                state.ensureTooltipVisible();
              })..resume();
            },
          ),
          SortButton( // sort with this column in ascending order
            toplevel.projectionsModel
          ).build(context, attribute, false),
          SortButton( // sort with this column in descending order
            toplevel.projectionsModel
          ).build(context, attribute, true),
          IconButton( // add a trace to plot with the data in this column
            icon: Icon(
              Icons.area_chart, color: ColorScheme.of(context).onSurface
            ),
            style: _buttonStyle,
            onPressed: () {
              final type = toplevel.pipelineModel.getAttrTypeByName(attribute);
              if(type.allowCast<num>()) {
                toplevel.plotterModel.addTrace(attribute);
                toplevel.expandToolView(Toolset.plotter);
              } else alertError(
                "Cannot plot non-numeric data!",
                "The column of type ${type.keyword} cannot be plotted.\n"
                "Hint: use " // TODO: prompt the user to plot other charts with analyzers
              );
            }
          )
        ]
      ),
      HeaderTrayMode.filterEdit => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 6),
          Select(
            selected: _filterMode,
            initialValue: FilterMode.equality,
            alignmentOffset: const Offset(-9, 0),
            dropdownIconColor:ColorScheme.of(context).onSurfaceVariant,
            anchorBuilder: (context, selected, icon) => Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 6),
                Text(selected.label, style: TextTheme.of(context).titleMedium!),
                const SizedBox(width: 6),
                icon
              ],
            ),
            optionsBuilder: (context, onTap) => [ for(
              final mode in FilterMode.values
            ) MenuItemButton(
              style: menuItemStyle,
              child: Text(mode.label),
              onPressed: () => onTap(mode),
            ) ],
          ),
          const SizedBox(width: 3),
          ValueListenableBuilder(
            valueListenable: _filterMode,
            builder: (context, mode, _) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: IntrinsicWidth(child: TextField(
                onSubmitted: filterEditSubmit,
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  contentPadding: const EdgeInsets.all(3),
                  enabledBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  hintText: mode.hint,
                ),
              ),
            ))
          ),
          /*IconButton( // accept
            icon: Icon(Icons.check, color: ColorScheme.of(context).primary),
            style: _buttonStyle,
            onPressed: () {

            },
          ),*/
          IconButton( // cancel
            icon: Icon(Icons.close, color: ColorScheme.of(context).error),
            style: _buttonStyle,
            onPressed: exitFilterEdit
          )
        ]
      )
    },
  );

  static void alertError(
    String title, String msg
  ) => FlutterPlatformAlert.showAlert(
    windowTitle: title,
    text: msg,
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );
}

final class CollectHeaderTray extends StatelessWidget {
  CollectHeaderTray(this.projections, this.attribute);

  final ProjectionsModel projections;
  final String attribute;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SortButton( // sort with this column in ascending order
        projections
      ).build(context, attribute, false),
      SortButton( // sort with this column in descending order
        projections
      ).build(context, attribute, true),
    ]
  );
}

extension type RowHeader(MonitorMode toplevel) {
  int rawIndex(int rowIndex) => toplevel.projectionsModel.current.indexAt(rowIndex);

  Widget build(BuildContext context, int rowIndex) => GestureDetector(
    onTap: () => toplevel.selectionsModel.add(rawIndex(rowIndex)),
    child: Container(
      alignment: Alignment.centerLeft,
      color: selectedOrNot(
        rowIndex,
        ColorScheme.of(context),
        (sch) => sch.primary,
        (sch) => sch.surfaceContainer
      ),
      padding: const EdgeInsets.symmetric(horizontal: cellPadding),
      child: Text("$rowIndex", style: selectedOrNot(
        rowIndex,
        TextTheme.of(context),
        (sch) => sch.bodyMedium!.copyWith(color: const Color(0xFFFFFFFF)),
        (sch) => sch.bodyMedium
      )),
    ).withTooltip(
      context,
      TextButton(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: rectBorder)
        ),
        child: Text("Collect", style: TextTheme.of(context).titleMedium),
        onPressed: () {
          toplevel.expandToolView(Toolset.collect);
          toplevel.selectionsModel.add(rawIndex(rowIndex));
        }
      )
    )
  );

  T selectedOrNot<I, T>(
    int rowIndex, I interm, T selected(I interm), T unselected(I interm)
  ) => toplevel.selectionsModel.isSelected(
    rawIndex(rowIndex)
  ) ? selected(interm) : unselected(interm);
}

extension type CollectRowHeader(ProjectionsModel collectProjections) {
  Widget build(BuildContext context, int rowIndex) => Container(
    alignment: Alignment.centerLeft,
    color: ColorScheme.of(context).surfaceContainer,
    padding: const EdgeInsets.symmetric(horizontal: cellPadding),
    child: Text("$rowIndex", style: TextTheme.of(context).bodyMedium),
  ).withTooltip(
    context,
    TextButton(
      child: Text("Remove", style: TextTheme.of(context).titleMedium),
      onPressed: () => collectProjections.current.remove(rowIndex),
      style: TextButton.styleFrom(
        shape: const RoundedRectangleBorder(borderRadius: rectBorder)
      )
    )
  );
}

extension EmbedIntoLine on Widget {
  InlineSpan inline() => WidgetSpan(child: this);
}

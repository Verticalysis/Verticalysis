// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domain/schema/AttrType.dart';
import '../models/FiltersModel.dart';
import '../models/ProjectionsModel.dart';
import 'shared/Clickable.dart';
import 'shared/Hoverable.dart';
import 'shared/Select.dart';
import 'MonitorMode.dart';
import 'Style.dart';
import 'ThemedWidgets.dart';

enum Mode {
  find(Icons.search, "Search", _search),
  filter(Icons.filter_alt, null, _filter);

  const Mode(this.icon, this.hint, this.onSubmit);

  final void Function(UnifinderController _) onSubmit;
  final IconData icon;
  final String? hint;

  static void _search(UnifinderController controller) {
    if(controller.keyword.isEmpty) return;
    controller._searching.moveNext();
  }

  static void _filter(UnifinderController controller) {

  }
}

final class ModeSwitcher extends StatelessWidget {
  final UnifinderController _controller;
  final ValueNotifier<bool> _hovering;

  ModeSwitcher(this._controller, this._hovering);

  @override
  Widget build(BuildContext context) => Select(
    selected: _controller._mode,
    initialValue: Mode.find,
    alignmentOffset: const Offset(-9, 0),
    anchorBuilder: (context, selected, icon) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 6),
        Icon(selected.icon, size: 21),
        ValueListenableBuilder(
          valueListenable: _hovering,
          child: icon,
          builder: (context, hovering, icon) => Visibility(
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: hovering,
            child: icon!
          )
        )
      ]
    ),
    optionsBuilder: (context, onTap) => [
      for(final mode in Mode.values) MenuItemButton(
        style: menuItemStyle,
        onPressed: () => onTap(mode),
        child: Icon(mode.icon, size: 21),
      ),
    ],
  );
}

extension type SearchController(MonitorMode toplevel) {
  Iterable<int> search(
    TextEditingController input, ValueNotifier<bool> caseSensitive
  ) sync* {
    int columnIndex = 0, rowIndex = 0;
    String keyword = "";
    String lowerCaseKeyword = ""; // precompute to avoid repetitive allocation
    while(true) {
      final (prevColumnIndex, prevRowIndex) = (columnIndex, rowIndex);
      if(keyword != input.text) {
        toplevel.selectionsModel.clear();
        columnIndex = rowIndex = 0;
        keyword = input.text;
        lowerCaseKeyword = keyword.toLowerCase();
      }
      final columns = toplevel.vcxController.visibleColumns;
      if(rowIndex >= toplevel.vcxController.entries) {
        ++columnIndex;
        rowIndex = 0;
      }
      if(columnIndex >= columns.length) columnIndex = 0;
      final (columnName, columnEntries) = columns[columnIndex];
      final type = toplevel.pipelineModel.getAttrTypeByName(columnName);
      if(type == AttrType.string) {
        rowIndex = columnEntries.indexWhere(_matcher(
          keyword, lowerCaseKeyword, caseSensitive
        ), rowIndex + 1);
      } else rowIndex = (
        columnEntries as StringfiedView
      ).typedView.indexWhere(type.from(keyword).matches, rowIndex + 1);
      if(rowIndex != -1) {
        toplevel.selectionsModel.add(
          toplevel.projectionsModel.current.indexAt(rowIndex)
        );
        toplevel.vcxController.highlight(rowIndex, columnName);
        yield rowIndex;
      } else { // search reached the end of a column
        ++columnIndex;
        rowIndex = 0;
        if(columnIndex >= columns.length) { // search reached the end
          final (_, entries) = columns[prevColumnIndex];
          if(type != AttrType.string ? !type.from(keyword).matches(
            (entries as StringfiedView).typedView[prevRowIndex]
          ) : !_matcher(keyword, lowerCaseKeyword, caseSensitive)(
            entries[prevRowIndex])
          ) yield -1;
          columnIndex = 0;
        }
      }
    }
  }

  static bool Function(String? _) _matcher(
    String keyword, String lowerCaseKeyword, ValueNotifier<bool> caseSensitive
  ) => caseSensitive.value ? keyword.partOfMatchCase : lowerCaseKeyword.partOf;
}

extension on String {
  bool partOfMatchCase(String? str) => str != null ? str.contains(this) : false;
  bool partOf(String? str) => str != null ? str.contains(this) : false;
}

extension on Comparable {
  bool matches(Comparable? rhs) => rhs != null ? rhs == this : false;
}

final class UnifinderController {
  factory UnifinderController(
    MonitorMode toplevel, [ String keyword = ""]
  ) => UnifinderController._(
    ValueNotifier(true),
    TagsEditingController(toplevel.filtersModel),
    TextEditingController(text: keyword),
    SearchController(toplevel)
  );

  UnifinderController._(
    this._case,
    this.tagsEditingController,
    this.textEditingController,
    SearchController searchController
  ): _searching = searchController.search(
    textEditingController, _case
  ).iterator;

  final TagsEditingController tagsEditingController;
  final TextEditingController textEditingController;
  final _mode = ValueNotifier(Mode.find);
  final ValueNotifier<bool> _case;

  final Iterator<int> _searching;

  Mode get mode => _mode.value;

  String get keyword => textEditingController.text;

  TextEditingController get editor => mode == Mode.filter ?
    tagsEditingController :
    textEditingController;

  void setMode([ Mode newMode = Mode.filter ]) {
    // tagsEditingController.tagEditMode = newMode == Mode.filter;
    _mode.value = newMode;
  }

  void toggleCaseSensitivity() => _case.value = !_case.value;

  void clear() => editor.clear();

  void discard() => tagsEditingController.dispose();
}

final class Unifinder extends StatelessWidget {
  final UnifinderController controller;
  final _hovering = ValueNotifier(false);

  static const _vPadding = 1.5;

  Unifinder(this.controller);

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: controller._mode,
    child: ModeSwitcher(controller, _hovering),
    builder: (context, mode, modeSwitcher) => MouseRegion(
      onEnter: (_) => _hovering.value = true,
      onExit: (_) => _hovering.value = false,
      child: Scrollbar(
        controller: _scrollController,
        child: TextField(
          maxLines: null,
          clipBehavior: Clip.hardEdge,
          scrollController: _scrollController,
          controller: controller.editor,
          // readOnly: mode == Mode.filter,
          onSubmitted: (content) => mode.onSubmit(controller),
          style: mode == Mode.filter ? const TextStyle(height: 2.4) : null,
          cursorHeight: 18,
          decoration: InputDecoration(
            hintText: mode.hint,
            contentPadding: const EdgeInsets.fromLTRB(2.4, _vPadding, 2.4, _vPadding),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(start: 12.0),
              child: modeSwitcher
            ),
            suffixIcon: ValueListenableBuilder(
              valueListenable: _hovering,
              child: Clickable(Hoverable().build((
                context, hovering, _
              ) => buildClearIcon(
                ColorScheme.of(context),
                hovering,
              )), onClick: controller.clear),
              builder: (context, hovering, clearButton) => Opacity(
                opacity: hovering ? 1 : 0.6,
                child: switch(mode) {
                  Mode.filter => clearButton,
                  Mode.find => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Clickable( // Case sensitive
                        onClick: controller.toggleCaseSensitivity,
                        ValueListenableBuilder(
                          valueListenable: controller._case,
                          builder: (
                            context, caseSensitive, _
                          ) => caseSensitive ? Hoverable().build((
                            context, hovering, _
                          ) => buildIcon(
                            Symbols.match_case_rounded,
                            ColorScheme.of(context),
                            hovering,
                            size: 21
                          )) : Hoverable().build((
                            context, hovering, _
                          ) => buildIcon(
                            Symbols.match_case_off_rounded,
                            ColorScheme.of(context),
                            hovering,
                            size: 21
                          ))
                        ),
                      ),
                      const SizedBox(width: 15),
                      Clickable( // next match
                        Hoverable().build((
                          context, hovering, _
                        ) => buildIcon(Icons.keyboard_arrow_down, ColorScheme.of(context), hovering)),
                        onClick: () => Mode.find.onSubmit(controller)
                      ),
                      const SizedBox(width: 15),
                      clearButton!,
                      const SizedBox(width: 12),
                    ]
                  )
                }
              )
            )
          ),
        )
      )
    )
  );
}

final class TagsEditingController extends TextEditingController {
  TagsEditingController(this._filters, { String? text }): super.fromValue(
    text == null ? TextEditingValue.empty : TextEditingValue(text: text)
  ) {
    _filters.addListener(_listener);
  }

  final FiltersModel _filters;

  /*bool _tagEditMode = false;

  set tagEditMode(bool enable) {
    _tagEditMode = enable;
    notifyListeners();
  }*/


  void clear() => _filters.clear();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing
  }) => TextSpan(
    text: _filters.isEmpty && text.isEmpty ? "Filter" : null,
    style: TextTheme.of(context).bodyLarge!.copyWith(
      color: ColorScheme.of(context).onSurfaceVariant
    ),
    children: _layoutTags(
      _filters.filters,
      TextTheme.of(context).bodyLarge!,
      ColorScheme.of(context)
    ));

  @override
  void dispose() {
    super.dispose();
    _filters.removeListener(_listener);
  }

  void _listener() {

  }

  List<InlineSpan> _layoutTags(List<Filter> filters, TextStyle style, ColorScheme sch) {
    final res = <InlineSpan>[];

    for(final (index, tag) in _filters.filters.indexed) {
      res.add(_buildTag(tag.label, index, sch));
      res.add(const WidgetSpan(child: SizedBox(width: 9, height: 9)));
    }

    res.add(TextSpan(text: text, style: TextStyle(color: sch.onPrimaryContainer)));

    return res;
  }

  WidgetSpan _buildTag(String label, int index, ColorScheme sch) => WidgetSpan(
    alignment: PlaceholderAlignment.middle,
    child: Chip(
      clipBehavior: Clip.antiAlias,
      backgroundColor: sch.onPrimaryFixed,
      shadowColor: Colors.transparent,
      onDeleted: () => _filters.remove(index),
      padding: const EdgeInsets.all(0),
      labelPadding: const EdgeInsets.fromLTRB(9, 0, 0, 1),
      deleteButtonTooltipMessage: "",
      deleteIcon: Container(
        height: 31,
        width: 36,
        transform: Matrix4.translationValues(1, 0, 0),
        margin: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        color: sch.primary,
        child: const Icon(Icons.close, color: Color(0xFFFFFFFF), size: 15)
      ),
      shape: _tagShape,
      label: Text(label, style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFFFFFFF)
      ))
    )
  );

  static const _tagShape = RoundedRectangleBorder(
    side: BorderSide(style: BorderStyle.none),
    borderRadius: BorderRadius.all(Radius.circular(6))/*BorderRadius.only(
      topRight: Radius.circular(20),bottomRight: Radius.circular(20)
    )*/
  );
}

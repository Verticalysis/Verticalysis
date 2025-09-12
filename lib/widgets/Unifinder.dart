// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/FiltersModel.dart';
import 'helper/Events.dart';
import 'helper/MonitorModeController.dart';
import 'helper/PhlexFilter.dart';
import 'helper/SearchController.dart';
import 'shared/Clickable.dart';
import 'shared/Hoverable.dart';
import 'shared/Select.dart';
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
    final searchCtrl = controller._searchController;

    searchCtrl.resetStateIfKeywordChanged(controller.keyword);

    final (found, freshStart) = searchCtrl.findNext(
      controller.keyword, controller._case.value
    );

    if(found) {
      searchCtrl.highlightMatch();
      controller._addSelection(searchCtrl.rowIndex);
    } else if(!freshStart) {
      if(searchCtrl.findNext(
        controller.keyword, controller._case.value
      ) case (true, _)) {
        searchCtrl.highlightMatch();
        controller._addSelection(searchCtrl.rowIndex);
        // TODO: hint user the search wrapped
      }
    }
  }

  static void _filter(UnifinderController controller) {
    final tagsCtl = controller.tagsEditingController;
    final submitFilter = (Filter filter) {
      controller.editor.text = "";
      tagsCtl._appendFilter(filter);
    };

    PhlexFilter.createNoThrow(
      tagsCtl.text,
      controller._attrAccessor,
      controller._columnAccessor,
      submitFilter,
      alertPhlexExprError
    );
  }

  static void alertPhlexExprError(
    String msg, StackTrace trace
  ) => FlutterPlatformAlert.showAlert(
    windowTitle: "Failed to filter with PHLEX expression",
    text: msg,
    alertStyle: AlertButtonStyle.ok,
    iconStyle: IconStyle.error,
  );
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

mixin KeywordMonitor {
  String _keyword = "";
  void Function() resetSelections = () {};

  void reset();

  void resetStateIfKeywordChanged(String keyword) {
    if(keyword ==_keyword) return;

    _keyword = keyword;
    resetSelections();
    reset();
  }
}

final class UnifinderSearchController = SearchController with KeywordMonitor;

final class UnifinderController {
  factory UnifinderController(
    MonitorModeController mmc, [ String keyword = ""]
  ) => UnifinderController._(
    ValueNotifier(true),
    TagsEditingController(mmc),
    TextEditingController(text: keyword),
    mmc
  );

  UnifinderController._(
    this._case,
    this.tagsEditingController,
    this.textEditingController,
    MonitorModeController mmc,
  ) : _addSelection = mmc.addSelection,
      _attrAccessor = mmc.getAttrTypeByName,
      _columnAccessor = mmc.getTypedColumn,
      _searchController = UnifinderSearchController(mmc.vcxController, mmc.pipelineModel) {
    _searchController.resetSelections = mmc.selectionsModel.clear;
    mmc.listen(Event.filterAppend, (_) {
      if(_mode.value != Mode.filter) _mode.value = Mode.filter;
    });
    _focusNode.onKeyEvent = (FocusNode node, KeyEvent evt) {
      if(!HardwareKeyboard.instance.isShiftPressed && evt.logicalKey.keyLabel == 'Enter') {
        if(evt is KeyDownEvent) _mode.value.onSubmit(this);
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    };
  }

  final void Function(int _) _addSelection;

  final TagsEditingController tagsEditingController;
  final TextEditingController textEditingController;
  final _mode = ValueNotifier(Mode.find);
  final ValueNotifier<bool> _case;

  final UnifinderSearchController _searchController;

  final AttrAccessor _attrAccessor;
  final ColumnAccessor _columnAccessor;

  final _focusNode = FocusNode();

  Mode get mode => _mode.value;

  String get keyword => textEditingController.text;

  TextEditingController get editor => mode == Mode.filter ?
    tagsEditingController :
    textEditingController;

  void toggleCaseSensitivity() => _case.value = !_case.value;

  void clear() => editor.clear();

  void discard() {
    tagsEditingController.dispose();
    _focusNode.dispose();
  }
}

final class Unifinder extends StatelessWidget {
  final UnifinderController controller;
  final _hovering = ValueNotifier(false);

  static const _vPadding = 1.5;

  final _scrollController = ScrollController();

  Unifinder(this.controller);

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
          focusNode: controller._focusNode,
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

final class TagsEditingController
  extends TextEditingController with FiltersModel {
  TagsEditingController(MonitorModeController mmc, {
    String? text
  }): _projectionAppendCh = mmc.getChannel(Event.projectionAppend),
    _projectionRemoveCh = mmc.getChannel(Event.projectionRemove),
    _projectionClearCh = mmc.getChannel(Event.projectionClear),
    super.fromValue(
    text == null ? TextEditingValue.empty : TextEditingValue(text: text)
  ) {
    mmc.listen(Event.filterAppend, _appendFilter);
  }

  final Channel<Notifer1<Filter>> _projectionAppendCh;
  final Channel<Notifer1<Iterable<Filter>>> _projectionRemoveCh;
  final Channel<VoidCallback> _projectionClearCh;

  void clear() {
    super.clear();
    clearFilters();
    _projectionClearCh.notify();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing
  }) => TextSpan(
    text: isFiltersEmpty && text.isEmpty ? "Filter" : null,
    style: TextTheme.of(context).bodyLarge!.copyWith(
      color: ColorScheme.of(context).onSurfaceVariant
    ),
    children: _layoutTags(
      filters,
      TextTheme.of(context).bodyLarge!,
      ColorScheme.of(context)
    ));

  @override
  void dispose() {
    super.dispose();
  }

  List<InlineSpan> _layoutTags(List<Filter> filters, TextStyle style, ColorScheme sch) {
    final res = <InlineSpan>[];

    for(final (index, tag) in filters.indexed) {
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
      onDeleted: () => _projectionRemoveCh.notify(removeFilter(index)),
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

  void _appendFilter(Filter filter) {
    appendFilter(filter);
    _projectionAppendCh.notify(filter);
  }

  static const _tagShape = RoundedRectangleBorder(
    side: BorderSide(style: BorderStyle.none),
    borderRadius: BorderRadius.all(Radius.circular(6))/*BorderRadius.only(
      topRight: Radius.circular(20),bottomRight: Radius.circular(20)
    )*/
  );
}

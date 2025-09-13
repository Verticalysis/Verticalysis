// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart' hide SearchController;
import 'package:material_symbols_icons/symbols.dart';

import '../../models/PipelineModel.dart';
import '../../models/ProjectionsModel.dart';
import '../../models/SelectionsModel.dart';
import '../helper/Events.dart';
import '../helper/Formatter.dart';
import '../helper/MonitorModeController.dart';
import '../helper/SearchController.dart';
import '../shared/Clickable.dart';
import '../shared/Decorations.dart';
import '../shared/Hoverable.dart';
import '../Style.dart';
import '../ThemedWidgets.dart';
import '../Verticell.dart';
import '../Verticatrix.dart';

/// The collect tool in the toolset
final class Collect extends StatelessWidget {
  final MonitorModeController mmc;
  final ProjectionsModel _projections;
  final CollectSearchController _searchController;

  SelectionsModel get _selections => mmc.selectionsModel;

  final _expandHeaders = ValueNotifier(true);
  final _caseSensitive = ValueNotifier(true);

  final primaryVcxController;
  final VerticatrixController linkedVcxController;

  static final phonyChangeNotifier = PhonyChangeNotifier();

  Collect(
    MonitorModeController mmc,
    ProjectionsModel projections,
    VerticatrixController linkedVcxController
  ) : this._(mmc, projections,  VerticatrixController(), linkedVcxController);

  Collect._(
    this.mmc,
    this._projections,
    this.primaryVcxController,
    this.linkedVcxController
  ) : _searchController = CollectSearchController(primaryVcxController, mmc.pipelineModel) {
    mmc.listen(Event.newColumns, (_) => syncAll());
    mmc.listen(Event.collectionAppend, (int index) {
      _projections.current.include([index]);
      primaryVcxController.entries = _projections.current.length;
      syncAll();
    });
    mmc.listen(Event.collectionRemove, (int row) {
      _projections.current.remove(row);
      primaryVcxController.entries = _projections.current.length;
    });
  }

  @override
  Widget build(BuildContext context) => Column(children: [
    DecoratedBox(
      decoration: BoxDecoration(
        color: ColorScheme.of(context).surface,
        boxShadow: [BoxShadow(
          color: ColorScheme.of(context).onSurface,
          blurRadius: 0.6
        )]
      ),
      child: Row(
        spacing: 6,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Add all selections",
            icon: Icon(
              Icons.add, size: 15, color: ColorScheme.of(context).onSurface
            ),
            padding: const EdgeInsets.all(3),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: rectBorder),
              fixedSize: const Size.square(13.5)
            ),
            onPressed: () {
              _projections.current.include(_selections.selections.toList());
              primaryVcxController.syncWith(linkedVcxController);
              syncAll();
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: "Clear",
            icon: Icon(
              Icons.delete, size: 15, color: ColorScheme.of(context).onSurface
            ),
            padding: const EdgeInsets.all(3),
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(borderRadius: rectBorder),
              fixedSize: const Size.square(13.5)
            ),
            onPressed: () {
              primaryVcxController.entries = 0;
              _projections.current.clear();
            }
          ),
          Vdivider(color: ColorScheme.of(context).onSurface),
          SizedBox(
            width: 360,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: "Search...",
                filled: true,
                fillColor: ColorScheme.of(context).surface,
                hoverColor: ColorScheme.of(context).surfaceBright,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 9, horizontal: 12
                ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 21,
                ),
                suffixIcon:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Clickable( // Case sensitive
                      onClick: () => _caseSensitive.value = !_caseSensitive.value,
                      ValueListenableBuilder(
                        valueListenable: _caseSensitive,
                        builder: (
                          context, caseSensitive, _
                        ) => caseSensitive ? Hoverable().build((
                          context, hovering, _
                        ) => buildIcon(
                          Symbols.match_case_rounded,
                          ColorScheme.of(context),
                          hovering,
                          size: 18
                        )) : Hoverable().build((
                          context, hovering, _
                        ) => buildIcon(
                          Symbols.match_case_off_rounded,
                          ColorScheme.of(context),
                          hovering,
                          size: 18
                        ))
                      ),
                    ),
                    const SizedBox(width: 12),
                  ]
                ),
              ),
              onSubmitted: (keyword) {
                if(keyword.isEmpty) return;
                _searchController.resetStateIfKeywordChanged(keyword);

                final (found, freshStart) = _searchController.findNext(
                  keyword, _caseSensitive.value
                );

                if(found) {
                  _searchController.highlightMatch();
                } else if(!freshStart) {
                  if(_searchController.findNext(
                    keyword, _caseSensitive.value
                  ) case (true, _)) {
                    _searchController.highlightMatch();
                    // TODO: hint user the search wrapped
                  }
                }
              },
            )
          ),
          /*Vdivider(color: ColorScheme.of(context).onSurface),
          SizedBox(
            width: 240,
            height: 33,
            child: CheckboxListTile(
              title: Text("Track selections"),
              value: true,
              onChanged: (newValue) {  },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),*/
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: _expandHeaders,
            builder: (context, expandHeaders, _) => IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: expandHeaders ? "Hide Headers" : "Show Headers",
              icon: RotatedBox(
                quarterTurns: expandHeaders ? 0 : 2,
                child: Icon(
                  Icons.keyboard_capslock,
                  size: 15,
                  color: ColorScheme.of(context).onSurface
                )
              ),
              padding: const EdgeInsets.all(3),
              style: IconButton.styleFrom(
                shape: const RoundedRectangleBorder(borderRadius: rectBorder),
                fixedSize: const Size.square(13.5)
              ),
              onPressed: () => _expandHeaders.value = !expandHeaders,
            ),
          )
        ]
      ),
    ),
    Expanded(child: ListenableBuilder(
      listenable: _projections,
      builder: (_, _) => ValueListenableBuilder(
        valueListenable: _expandHeaders,
        builder: (context, expandHeaders, _) => buildVerticatrix(
          ColorScheme.of(context),
          TextTheme.of(context),
          syncAll(),
          expandHeaders ?
          CollectHeaderBuilder(_projections).build :
          (_, _, _, _) => SizedBox.shrink(),
          CollectRowHeaderBuilder(mmc).build,
          phonyChangeNotifier,
          Formatter.formatters,
          showHeaderBackground: expandHeaders
        )
      )
    ))
  ]);

  VerticatrixController syncAll() => primaryVcxController..syncWith(
    linkedVcxController
  )..syncColumns((id) {
    return _projections.getColumn(id, mmc.pipelineModel.getAttrTypeByName);
  }, _projections.current.length);
}

mixin KeywordMonitor {
  String _keyword = "";

  void reset();

  void resetStateIfKeywordChanged(String keyword) {
    if(keyword ==_keyword) return;

    _keyword = keyword;
    reset();
  }
}

final class CollectSearchController = SearchController with KeywordMonitor;

class PhonyChangeNotifier extends ChangeNotifier {}

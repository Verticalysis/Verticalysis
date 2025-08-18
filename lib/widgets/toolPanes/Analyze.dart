// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:sliver_sticky_collapsable_panel/sliver_sticky_collapsable_panel.dart';

import '../../domain/analysis/Analyzer.dart';
import '../../models/AnalysisCandidates.dart';
import '../../models/ProjectionsModel.dart';
import '../helper/AnalyzersController.dart';
import '../helper/Events.dart';
import '../helper/MonitorModeController.dart';
import '../shared/Clickable.dart';
import '../shared/FadedSliver.dart';
import '../shared/Hoverable.dart';
import '../Style.dart';

final class ResizeState {
  double prevCursor = 0;
  double startWidth = 0;
}

/// The analyze tool in the toolset
final class Analyze extends StatelessWidget {
  final _rightWidth = ValueNotifier(570.0);
  final resizeState = ResizeState();

  static const _minRightWidth = 240.0;

  final _scrollController = ScrollController();
  final tabsctl = TabbedViewController([]);
  final analysisCandidates = AnalysisCandidates();

  static const _entryInset = EdgeInsets.symmetric(vertical: 6, horizontal: 12);

  TabData newPage() {
    final page = TabData(text: "Start Analysis");
    page.content = AnalysisSession(page, analysisCandidates);
    return page;
  }

  Analyze(MonitorModeController mmc) {
    tabsctl.addTab(newPage());
    mmc.listen(
      Event.selectRegionUpdate,
      (int startRow, int endRow, Iterable<(String, List<String?>)> columns) {
        analysisCandidates.update([ for(
          final (name, column) in columns
        ) AnalysisCandidate<StringfiedView>(
          name, mmc.pipelineModel.getAttrTypeByName(name), column as StringfiedView
        )], startRow, endRow);
      }
    );
  }

  Widget _headerBuilder(BuildContext context, String text, IconData icon
  ) => Container(
    alignment: Alignment.topLeft,
    padding: const EdgeInsets.fromLTRB(15, 4, 15, 5),
    width: double.infinity,
    color: ColorScheme.of(context).surface,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: TextTheme.of(context).titleSmall),
        Icon(icon, color: ColorScheme.of(context).onSurfaceVariant),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: ColorScheme.of(context).surfaceContainer,
      boxShadow: [BoxShadow(
        color: ColorScheme.of(context).onSurface,
        offset: Offset(0, -0.3),
        blurRadius: 0.1,
      )]
    ),
    child: Row(children: [ Expanded(child: ListenableBuilder(
      listenable: analysisCandidates,
      builder: (context, _) => CustomScrollView(
        controller: _scrollController,
        slivers: [ if(analysisCandidates.isEmpty) SliverToBoxAdapter(
          child: _headerBuilder(
            context, "Select the cells to analyze", Icons.expand_more
          )
        ), for(
          final (name, data) in analysisCandidates.stringfied
        ) SliverStickyCollapsablePanel(
          scrollController: _scrollController,
          controller: StickyCollapsablePanelController(
            key: '$name${analysisCandidates.start}-${analysisCandidates.end}'
          ),
          headerBuilder: (context, status) => MouseRegion(
            cursor: SystemMouseCursors.click,
            child: _headerBuilder(
              context,
              name,
              status.isExpanded ? Icons.expand_more : Icons.expand_less
            )
          ),
          sliverPanel: SliverList.list(
            children: [ for(
              final (i, entry) in data.indexed
            ) IntrinsicHeight(child:
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    padding: _entryInset,
                    width: analysisCandidates.numberColWidth + 20,
                    child: Text((i + analysisCandidates.start).toString()),
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(
                        color: ColorScheme.of(context).onSurface,
                        width: 0.5
                      ))
                    ),
                  ),
                  Padding(
                    padding: _entryInset,
                    child: SelectableText(entry ?? "")
                  )
                ]
              )
            ) ]
          ),
        )],
      ),
    )),
    Stack(children: [
      ValueListenableBuilder(
        valueListenable: _rightWidth,
        builder: (context, width, tabs) => SizedBox(width: width, child: tabs),
        child: TabbedViewTheme(
          data: tabCosmeticFromTheme(ColorScheme.of(context)),
          child: TabbedView(
            controller: tabsctl,
            selectToEnableButtons: false,
            tabsAreaButtonsBuilder: (context, tabsCount) => [ TabButton(
              icon: IconProvider.data(Icons.add),
              onPressed: () {
                tabsctl.addTab(newPage());
                tabsctl.selectedIndex = tabsctl.tabs.length - 1;
              }
            )],
            tabCloseInterceptor: (index, tabData) {
              if(tabsctl.length == 1) {
                tabsctl.addTab(newPage());
              } else {
                final selected = tabsctl.selectedIndex!;
                if(index <= selected) {
                  if(index == selected - 1) {
                    if(index != 0) {
                      tabsctl.reorderTab(selected, index);
                      tabsctl.selectedIndex = index;
                      tabsctl.removeTab(selected);
                      return false;
                    } else tabsctl.selectedIndex = 0;
                  } else if(selected != 0) tabsctl.selectedIndex = selected - 1;
                }
              }
              return true;
            }
          ),
        ),
      ),
      Positioned( // resizer
        top: 32,
        bottom: 0,
        left: 0,
        width: 5,
        child: MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onPanStart: (details) {
              resizeState.prevCursor = details.globalPosition.dx;
              resizeState.startWidth = _rightWidth.value;
            },
            onPanUpdate: (details) {
              final newWidth = resizeState.startWidth
                - details.globalPosition.dx
                + resizeState.prevCursor;
              if(newWidth >= _minRightWidth) {
                _rightWidth.value = newWidth;
              }
            },
          ),
        ),
      ),
    ])
  ]));

  static TabbedViewThemeData tabCosmeticFromTheme(ColorScheme scheme) {
    final outline = BorderSide(color: scheme.onSurface.withAlpha(72), width: 1);

    return TabbedViewThemeData(
      tabsArea: TabsAreaThemeData(
        buttonIconSize: 18,
        buttonPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        normalButtonColor: scheme.onSurfaceVariant,
        hoverButtonColor: scheme.primary,
        gapBottomBorder: outline,
        color: scheme.surface
      ),
      tab: TabThemeData(
        padding: const EdgeInsets.fromLTRB(12, 3, 5, 6),
        buttonsOffset: 8,
        hoverButtonColor: scheme.error,
        textStyle: TextStyle(fontSize: 13, color: scheme.onPrimaryContainer),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          border: Border(
            top: BorderSide(width: 3, color: scheme.surface),
            bottom: outline,
          )
        ),
        draggingDecoration: BoxDecoration(border: Border.symmetric(
          horizontal: BorderSide(width: 6, color: scheme.surface),
          vertical: BorderSide(width: 6, color: scheme.surface)
        )),
        selectedStatus: TabStatusThemeData(decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border(
            top: BorderSide(width: 3, color: scheme.primary),
            bottom: BorderSide(color: scheme.surfaceContainer, width: 1),
            right: outline,
            left: outline,
          )
        )),
        highlightedStatus: TabStatusThemeData(decoration: BoxDecoration(
          color: scheme.surfaceDim,
          border: Border(
            top: BorderSide(width: 3, color: scheme.surfaceDim),
            bottom: outline
          )
        )),
      ),
      contentArea: ContentAreaThemeData(
        decoration: BoxDecoration(border: Border(left: BorderSide(
          color: scheme.onSurface,
          width: 0.7
        )))
      )
    );
  }
}

final class AnalysisSession extends StatelessWidget {
  AnalysisSession(this._container, this._analysisCandidates);

  final TabData _container;

  final _controller = AnalyzersCotroller();
  final _selected = ValueNotifier(0);
  final _scrollController = ScrollController();
  final AnalysisCandidates _analysisCandidates;

  static const _inactiveEntry = BoxDecoration();
  static const _hoveringEntry = BoxDecoration(color: optionHovered);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(       // analyzers list
        width: 192,
        child: FadedSliver(
          scrollController: _scrollController,
          child: ValueListenableBuilder(
            valueListenable: _selected,
            builder: (context, selected, _) => ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.all(0.0),
              itemCount: _controller.analyzers,
              itemBuilder: (context, i) => Clickable(
                HoverEffect(
                  height: 42,
                  align: Alignment.centerLeft,
                  padding: const EdgeInsets.fromLTRB(15, 6, 12, 6),
                  inactiveCosmetic: _inactiveEntry,
                  hoveringCosmetic: _hoveringEntry,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_controller.enumerate(i).name, style: TextStyle(
                        fontSize: 15,
                        color: selected == i ?
                          ColorScheme.of(context).primary :
                          ColorScheme.of(context).onSurfaceVariant
                      )),
                      Tooltip(
                        message: _controller.enumerate(i).isVectorAnalyzer ?
                          "Vector Analysis" :
                          "Scalar Analysis",
                        child: Icon(
                          _controller.enumerate(i).isVectorAnalyzer ?
                            Icons.playlist_add_check:
                            Icons.checklist_rtl,
                          color: ColorScheme.of(context).onSurfaceVariant,
                          size: 20
                        )
                      )
                    ],
                  )
                ),
                onClick: () => _selected.value = _controller.updatePanel(i)
              ),
              separatorBuilder: (context, _) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 13),
                color: ColorScheme.of(context).onSurface,
                height: 0.6,
              ),
            ),
          )
        )
      ),
      Expanded(child: SingleChildScrollView(  // details of the selected
        padding: const EdgeInsets.fromLTRB(15, 0, 12, 0),
        child: ValueListenableBuilder(
          valueListenable: _selected,
          builder: (context, selected, _) => Column(children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_controller.enumerate(selected).name, style: TextStyle(
                  color: ColorScheme.of(context).onSurfaceVariant,
                  fontSize: 20
                )),
                Clickable(
                  HoverEffect(
                    inactiveCosmetic: BoxDecoration(
                      color: ColorScheme.of(context).onPrimaryFixed,
                      borderRadius: const BorderRadius.all(Radius.circular(3))
                    ),
                    hoveringCosmetic: BoxDecoration(
                      color: ColorScheme.of(context).primary,
                      borderRadius: const BorderRadius.all(Radius.circular(3))
                    ),
                    align: const Alignment(.0, -0.1),
                    height: 27,
                    width: 72,
                    child: Text("Analyze", style: TextStyle(
                      fontSize: 13, color: Color(0xFFFFFFFF)
                    )),
                  ),
                  onClick: () {
                    final analyzer = _controller.enumerate(selected);
                    _container.text = analyzer.name;
                    if(analyzer.isVectorAnalyzer) {
                      _container.content = _controller.vectorAnalysis(
                        selected, _analysisCandidates.candidates, context
                      );
                    } else {
                      final entries = _controller.scalarAnalysis(
                        selected, _analysisCandidates.candidates, context
                      );
                      _container.content = ListView.separated(
                        padding: EdgeInsets.all(0.0),
                        itemCount: _analysisCandidates.length,
                        itemBuilder: (context, i) => entries[i],
                        separatorBuilder: (context, _) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 13),
                          color: ColorScheme.of(context).onSurface,
                          height: 0.6,
                        ),
                      );
                    }
                  }
                )
              ]
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(0, 7, 0, 10),
              color: ColorScheme.of(context).onSurface,
              width: double.infinity,
              height: 1,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _controller.buildPanel(context)
              )
            )
          ])
        )
      )),
    ],
  );
}

extension on TabbedViewController {
  bool get isEmpty => this.length == 0;
}

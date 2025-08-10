// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:provider/provider.dart';
import 'package:tabbed_view/tabbed_view.dart';

import '../domain/analysis/Analyzer.dart';
import '../domain/frontend/adapter/AnnotatedCSVadapter.dart';
import '../domain/amorphous/EventManifold.dart';
import '../domain/amorphous/Projection.dart';
import '../domain/byteStream/ByteStream.dart';
import '../domain/schema/Schema.dart';
import '../models/AnalysisCandidates.dart';
// import '../models/ConfigModels.dart';
import '../models/FiltersModel.dart';
import '../models/PipelineModel.dart';
import '../models/PlotterModel.dart';
import '../models/ProjectionsModel.dart';
import '../models/SchemasModel.dart';
import '../models/ScrollModel.dart';
import '../models/SelectionsModel.dart';
import '../utils/EnhancedPatterns.dart';
// import '../models/SkipListModel.dart';
import 'helper/Events.dart';
import 'helper/Formatter.dart';
import 'helper/LoadWithSchema.dart';
import 'shared/Latch.dart';
import 'shared/NestedMenu.dart';
import 'toolPanes/Analyze.dart';
import 'toolPanes/Collect.dart';
import 'toolPanes/Plotter.dart';
import 'MiniMap.dart';
import 'Style.dart';
import 'ThemedWidgets.dart';
import 'Unifinder.dart';
import 'Verticell.dart';
import 'Verticatrix.dart';

enum Toolset {
  none(""),
  analyze("Analyze"),
  collect("Collect"),
  plotter("Visualize");

  const Toolset(this.label);
  final String label;
}

final class ResizeState {
  double prevCursorY = 0;
  double startHeight = 0;
}

final class MonitorMode extends StatelessWidget {
  final TabData container;

  final _toolHeight = ValueNotifier(.0);
  final _toolView = ValueNotifier(Toolset.none);
  final resizeState = ResizeState();

  final _toolset = <Widget>[];

  static const minToolHeight = 60;

  final EventDispatcher dispatcher;
  final analyzeModel = AnalysisCandidates();
  final scrollModel = ScrollModel();
  final selectionsModel = SelectionsModel();
  final vcxController = VerticatrixController();
  final PipelineModel pipelineModel;
  final ProjectionsModel projectionsModel;
  final SchemasModel schemasModel;
  late final UnifinderController unifinderController;

  bool get toolVisible => _toolView.value != Toolset.none;

  /*factory MonitorMode(
    ByteStream stream, Schema schema, SchemasModel schemas, TabData container
  ) {
    final evtManifold = EventManifold(onStreamError);
    final pipelineModel = PipelineModel(evtManifold);
    final projectionsModel = ProjectionsModel(
      evtManifold, schema.chronologicallySortedBy
    );
    return MonitorMode._(
      stream,
      schema,
      schemas,
      FiltersModel(),
      pipelineModel,
      projectionsModel,
      EventManifold(onStreamError),
      container
    );
  }

  MonitorMode._(
    ByteStream stream,
    Schema schema,
    this.schemasModel,
    this.filtersModel,
    this.pipelineModel,
    this.projectionsModel,
    EventManifold evtManifold,
    this.container
  ): unifinderController = UnifinderController(filtersModel) {
    container.value = dispose;
    WidgetsBinding.instance.addObserver(
      WindowSizeObserver(updateScrollModel, this)
    );
    projectionsModel.onSizeChange = onEntriesUpdate;
    projectionsModel.preNotify = () => vcxController.syncColumns((name) {
      return projectionsModel.getColumn(name, pipelineModel.getAttrTypeByName);
    }, projectionsModel.currentLength);
    filtersModel.onRemove = (trailing) => projectionsModel.splice(trailing);
    vcxController.onRegionSelect = onRegionUpdate;
    vcxController.onScroll = updateScrollModel;
    evtManifold.onNewColumns = (columns) {
      print(columns);
      for(final column in columns) vcxController.addColumn(
        column, projectionsModel.getColumn(
          column, pipelineModel.getAttrTypeByName
        )
      );
    };
    pipelineModel.connect(schema, stream);
  }*/

  MonitorMode(
    ByteStream stream, Schema schema, SchemasModel schemas, TabData container
  ): this._(
    stream,
    schema,
    schemas,
    EventManifold(onStreamError),
    EventDispatcher(Event.values),
    container
  );

  MonitorMode._(
    ByteStream stream,
    Schema schema,
    this.schemasModel,
    EventManifold evtManifold,
    this.dispatcher,
    this.container
  ): pipelineModel = PipelineModel(evtManifold)..connect(schema, stream),
    projectionsModel = ProjectionsModel(
      evtManifold, schema.chronologicallySortedBy
    ) {
    _toolset.add(Analyze(analyzeModel));
    _toolset.add(Collect(this, ProjectionsModel.single(
      projectionsModel.current.cleared
    ), vcxController));
    _toolset.add(Plotter(dispatcher, projectionsModel, pipelineModel));
    unifinderController = UnifinderController(this, dispatcher);
    container.value = dispose;
    WidgetsBinding.instance.addObserver(
      WindowSizeObserver(updateScrollModel, this)
    );
    projectionsModel.onSizeChange = onEntriesUpdate;
    projectionsModel.preNotify = () => vcxController.syncColumns((name) {
      return projectionsModel.getColumn(name, pipelineModel.getAttrTypeByName);
    }, projectionsModel.currentLength);
    vcxController.onRegionSelect = onRegionUpdate;
    vcxController.onScroll = updateScrollModel;
    evtManifold.onNewColumns = (columns) {
      for(final column in columns) vcxController.addColumn(
        column, projectionsModel.getColumn(
          column, pipelineModel.getAttrTypeByName
        )
      );
    };
    dispatcher.listen(
      Event.projectionAppend,
      (Filter filter) => projectionsModel.append(filter)
    );
    dispatcher.listen(
      Event.projectionRemove,
      (Iterable<Filter> filter) => projectionsModel.splice(filter)
    );
    dispatcher.listen(
      Event.projectionClear,
      () => projectionsModel.clear()
    );
    dispatcher.listen(
      Event.expandToolView,
      (Toolset tool) => expandToolView(tool)
    );
    dispatcher.syncChannels();
  }

  void onRegionUpdate(
    int startRow, int endRow, Iterable<(String, List<String?>)> columns
  ) {
    analyzeModel.update([ for(
      final (name, column) in columns
    ) AnalysisCandidate<StringfiedView>(
      name, pipelineModel.getAttrTypeByName(name), column as StringfiedView
    )], startRow, endRow);
    expandToolView(Toolset.analyze);
  }

  void onEntriesUpdate(
    int entries
  ) => WidgetsBinding.instance.addPostFrameCallback((_) {
    vcxController.entries = entries;
    updateScrollModel();
  });

  void updateScrollModel() => scrollModel.setBothEdges(
    vcxController.normalizedOffset,
    vcxController.normalizedLowerEdge(),
    projectionsModel.scrollReference
  );

  void onMiniMapSliderDrag(double normalizedDelta) {
    vcxController.scroll2index(
      scrollModel.updateByDelta(
        normalizedDelta,
        vcxController.normalizedHeight,
        projectionsModel.scrollReference,
      )
    );
  }

  void expandToolView(Toolset tool) {
    _toolHeight.value = _toolHeight.value == 0 ? 180 : _toolHeight.value.abs();
    _toolView.value = tool;
  }

  void sortBy(String attribute, bool descending) {
    projectionsModel.sort(attribute, descending);
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ColorScheme.of(context).surfaceContainer,
    child: Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surface,
            boxShadow: [BoxShadow(
            offset: const Offset(.0, 0.6),
            color: ColorScheme.of(context).onSurface,
            blurRadius: 0.6
          )]
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 9,
          children: [
            NestedMenu(
              buildActions(TextTheme.of(context).titleMedium)
            ).withIcon(
              Icon(
                Icons.auto_awesome_mosaic_outlined,
                color: ColorScheme.of(context).onSurface,
              ),
              cursor: SystemMouseCursors.basic,
              iconSize: 27,
            ),
            Expanded(child: SizedBox(
              height: 40,
              child: ClipRect( // https://github.com/flutter/flutter/issues/153240
                child: Unifinder(unifinderController)
              )
            ))
          ]
        ),
      ),
      MiniMap(
        projectionsModel,
        scrollModel,
        selectionsModel,
        onMiniMapSliderDrag,
        108
      ),
      Expanded(child: Container(
        child: Theme(
          data: Theme.of(context).copyWith(
            hoverColor: ColorScheme.of(context).primary.withAlpha(60)
          ),
          child: ListenableBuilder( // Verticatrix
            listenable: projectionsModel,
            builder: (context, _) => buildVerticatrix(
              ColorScheme.of(context),
              TextTheme.of(context),
              vcxController,
              PrimaryHeaderBuilder(this).build,
              PrimaryRowHeaderBuilder(this).build,
              selectionsModel,
              Formatter.formatters,
            )
          ),
        ),
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surfaceContainer,
          boxShadow: [BoxShadow(
            offset: const Offset(.0, -0.6),
            color: ColorScheme.of(context).onSurface,
            blurRadius: 0.6
          )]
        ),
      )),
      Stack(children: [
        ValueListenableBuilder( // tool view
          valueListenable: _toolView,
          builder: (context, toolView, _) => IndexedStack(
            index: toolView.index - 1,
            children: [ for(
              final tool in Toolset.values.skip(1)
            ) ValueListenableBuilder( // tool view
              valueListenable: _toolHeight,
              child: _toolset[tool.index - 1],
              builder: (context, height, childTool) => SizedBox(
                height: toolView == tool ? _toolHeight.value : 0,
                // width: MediaQuery.of(context).size.width,
                child: childTool
              )
            )],
          )
        ),
        ValueListenableBuilder( // resizer at the top of the tool view
          valueListenable: _toolView, // No resizer when no tool is shown
          builder: (context, toolMode, _) => Positioned( // resizer
            top: 0,
            left: 0,
            right: 0,
            child: toolMode == Toolset.none ? _void : MouseRegion(
              opaque: false,  // pass through scroll event
              cursor: SystemMouseCursors.resizeRow,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  resizeState.prevCursorY = details.globalPosition.dy;
                  resizeState.startHeight = _toolHeight.value;
                },
                onPanUpdate: (details) {
                  final newHeight = resizeState.startHeight - (
                    details.globalPosition.dy
                    - resizeState.prevCursorY
                  );
                  if(newHeight >= minToolHeight) {
                    _toolHeight.value = newHeight;
                  }
                },
                onPanEnd: (_) {
                  scrollModel.setLowerEdge(
                    vcxController.normalizedLowerEdge(),
                    projectionsModel.scrollReference
                  );
                },
                child: const SizedBox(height: 8,),
              ),
            ),
          ),
        )
      ]),//),
      Container( // footer
        decoration: BoxDecoration(
          color: ColorScheme.of(context).surface,
          boxShadow: [BoxShadow(
            color: ColorScheme.of(context).onSurface,
            blurRadius: 0.6
          )]
        ),
        child: ValueListenableBuilder(
          valueListenable: _toolView,
          builder: (context, toolView, _) => Row(children: [
            for(final tool in Toolset.values.skip(1)) Latch(
              tool.label,
              _toolView.value == tool ?
                ColorScheme.of(context).primary :
                ColorScheme.of(context).onSurface,
              textStyle: TextTheme.of(context).bodyMedium!,
              hoveringColor: ColorScheme.of(context).surfaceBright,
              onClick: () {
                if(_toolView.value == tool) {
                  _toolHeight.value = -_toolHeight.value;
                  _toolView.value = Toolset.none;
                } else expandToolView(tool);
              }
            ),
            const Spacer(),
            Container(
              /*child: ValueListenableBuilder(
                valueListenable: ,
                builder: (context, , _) => Text(),
              )*/
            )
          ])
        )
      )
      //)
    ])
  );

  List<Widget> buildActions(TextStyle? itemStyle) => [
    SubmenuButton(
      style: menuItemStyle,
      child: Text("Interleave", style: itemStyle),
      menuChildren: [ for(final sch in Iterable.generate(
        schemasModel.length, schemasModel.enumSchema
      )) MenuItemButton(
        style: menuItemStyle,
        child: Text(sch, style: itemStyle),
        onPressed: () {
          schemasModel.getSchemaNoThrow(sch, (schema, _) async {
            final result = await FilePicker.platform.pickFiles();
            if(result != null) {
              ByteStreamLoader.load(
                AddressFamily.file,
                result.path,
                (stream) => pipelineModel.connect(schema, stream)
              );
              // TODO: notify plotter for potential new reference columns
            }
          });
        },
      )],
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Hide entry numbers", style: itemStyle),
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Select all entries", style: itemStyle),
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Unselect all entries", style: itemStyle),
    ),
    SubmenuButton(
      style: menuItemStyle,
      child: Text(
        "Export as ...",
        style: itemStyle
      ),
      menuChildren: [
        for(final (name, formatter) in Formatter.formatters) MenuItemButton(
          style: menuItemStyle,
          child: Text(name, style: itemStyle),
          onPressed: () {}
        )
      ],
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("Scroll to bottom on update", style: itemStyle)
    ),
    MenuItemButton(
      style: menuItemStyle,
      child: Text("About", style: itemStyle)
    )
  ];

  void dispose() {
    pipelineModel.discard();
    WidgetsBinding.instance.removeObserver(WindowSizeObserver(() {}, this));
    unifinderController.discard();
    vcxController.dispose();
  }

  static const _void = SizedBox.shrink();

  static void onStreamError(Object? error, StackTrace t) => switch(error) {
    final MissingAttributeException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Missing Attribute in Source',
      text: "${except.attribute} is declared in the schema but not found.",
      iconStyle: IconStyle.warning,
    ),
    final FormatException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Source Format Error',
      text: "${except.message} ${except.source}line: ${except.offset}\n $t",
      iconStyle: IconStyle.warning,
    ),
    final FileSystemException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'File System Error',
      text: "An error occurred when reading ${except.path}: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final SocketException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Socket Error',
      text: "${except.address} connection lost: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final ProcessException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Subprocess Error',
      text: "${except.executable} reported an error: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final StdoutException except => FlutterPlatformAlert.showAlert(
      windowTitle: 'Subprocess stdout Error',
      text: "An error occurred when reading from stdout: ${except.message}",
      iconStyle: IconStyle.warning,
    ),
    final IOException _ => FlutterPlatformAlert.showAlert(
      windowTitle: 'Unknown IO Error',
      text: "An error occurred when reading from stream.",
      iconStyle: IconStyle.warning,
    ),
    _ => FlutterPlatformAlert.showAlert(
      windowTitle: 'Unknown Error',
      text: error.toString(),
      iconStyle: IconStyle.warning,
    ),
  };
}

final class WindowSizeObserver with WidgetsBindingObserver {
  WindowSizeObserver(this.onWindowSizeChange, this.toplevel);
  VoidCallback onWindowSizeChange;
  MonitorMode toplevel;

  @override
  void didChangeMetrics() => WidgetsBinding.instance.addPostFrameCallback((_) {
    onWindowSizeChange();
  });

  @override
  bool operator ==(Object rhs) => switch(rhs) {
    final WindowSizeObserver rhs => rhs.toplevel == toplevel,
    _ => false
  };
}
